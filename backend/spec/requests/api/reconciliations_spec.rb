require "rails_helper"

# Reconcile action API (issue 17): the caller re-enters each money source's real
# balance and the server writes the Adjustment transactions that absorb the
# drift from the Current balance (ReconcileService, issue 12), atomically. The
# security properties are authorization (cross-user source rejected), validation
# (422), and the money-correctness invariant that the resulting Adjustment lands
# the source's Current balance exactly on the re-entered reality (no float —
# ADR-0015). Every response is asserted against the OpenAPI contract (ADR-0017).
RSpec.describe "Api::Reconciliations", type: :request do
  let(:alice) { Auth::PasswordProvider.register(username: "alice", password: "secret123") }
  let(:bob)   { Auth::PasswordProvider.register(username: "bob",   password: "secret123") }

  def auth_headers(user, body: false)
    headers = { "Accept" => "application/json" }
    headers["Content-Type"] = "application/json" if body
    headers["Authorization"] = "Bearer #{Auth::TokenService.issue_access_token(user)}" if user
    headers
  end

  def create_source(user, body)
    post "/api/sources", params: body.to_json, headers: auth_headers(user, body: true)
    response.parsed_body["id"]
  end

  def reconcile(user, balances)
    post "/api/reconciliations", params: { balances: balances }.to_json,
                                 headers: auth_headers(user, body: true)
  end

  def balance_of(user, source_id)
    get "/api/sources/#{source_id}", headers: auth_headers(user)
    response.parsed_body["current_balance"]["amount_minor"]
  end

  def vnd_account(user, opening: 0, name: "VPBank")
    create_source(user, { kind: "account", name: name, currency: "VND", opening_minor_units: opening })
  end

  describe "POST /api/reconciliations writes the right Adjustments" do
    it "writes a positive Adjustment when reality is higher than computed" do
      acct = vnd_account(alice, opening: 1_000_000)

      reconcile(alice, [ { source_id: acct, amount_minor_units: 1_500_000, currency: "VND", note: "Found cash" } ])

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body["unchanged_source_ids"]).to eq([])
      expect(body["adjustments"].size).to eq(1)
      adj = body["adjustments"].first
      expect(adj).to include("kind" => "adjustment", "source_id" => acct, "note" => "Found cash")
      expect(adj["amount"]).to eq("amount_minor" => 500_000, "currency" => "VND")
      expect(balance_of(alice, acct)).to eq(1_500_000)
    end

    it "writes a negative Adjustment when reality is lower than computed" do
      acct = vnd_account(alice, opening: 1_000_000)

      reconcile(alice, [ { source_id: acct, amount_minor_units: 600_000, currency: "VND" } ])

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(response.parsed_body["adjustments"].first["amount"]).to eq("amount_minor" => -400_000, "currency" => "VND")
      expect(balance_of(alice, acct)).to eq(600_000)
    end

    it "writes no Adjustment when reality already matches the Current balance" do
      acct = vnd_account(alice, opening: 1_000_000)

      reconcile(alice, [ { source_id: acct, amount_minor_units: 1_000_000, currency: "VND" } ])

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body["adjustments"]).to eq([])
      expect(body["unchanged_source_ids"]).to eq([ acct ])
      expect(alice.transactions.count).to eq(0)
    end

    it "reconciles several sources at once, one Adjustment each where they drifted" do
      a = vnd_account(alice, opening: 1_000_000, name: "A")
      b = vnd_account(alice, opening: 500_000, name: "B")
      c = vnd_account(alice, opening: 200_000, name: "C")

      reconcile(alice, [
        { source_id: a, amount_minor_units: 1_200_000, currency: "VND" }, # +200_000
        { source_id: b, amount_minor_units: 500_000,   currency: "VND" }, # unchanged
        { source_id: c, amount_minor_units: 150_000,   currency: "VND" }  # -50_000
      ])

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body["adjustments"].map { |x| x["source_id"] }).to contain_exactly(a, c)
      expect(body["unchanged_source_ids"]).to eq([ b ])
      expect(balance_of(alice, a)).to eq(1_200_000)
      expect(balance_of(alice, c)).to eq(150_000)
    end

    it "reconciles against the Current balance, not just the opening (folds prior transactions)" do
      acct = vnd_account(alice, opening: 1_000_000)
      post "/api/transactions",
           params: { kind: "expense", source_id: acct, amount_minor_units: 300_000, currency: "VND" }.to_json,
           headers: auth_headers(alice, body: true)
      expect(balance_of(alice, acct)).to eq(700_000) # computed Current balance

      reconcile(alice, [ { source_id: acct, amount_minor_units: 750_000, currency: "VND" } ])

      expect(response).to have_http_status(:created)
      # Drift is reality − computed = 750_000 − 700_000 = +50_000.
      expect(response.parsed_body["adjustments"].first["amount"]).to eq("amount_minor" => 50_000, "currency" => "VND")
      expect(balance_of(alice, acct)).to eq(750_000)
    end
  end

  describe "atomicity (all-or-nothing)" do
    it "writes no Adjustments when one write fails part-way" do
      a = vnd_account(alice, opening: 1_000_000, name: "A")
      b = vnd_account(alice, opening: 1_000_000, name: "B")

      original = Transaction.instance_method(:save!)
      allow_any_instance_of(Transaction).to receive(:save!) do |instance|
        raise ActiveRecord::RecordInvalid, instance if instance.note == "BOOM"

        original.bind(instance).call
      end

      reconcile(alice, [
        { source_id: a, amount_minor_units: 900_000, currency: "VND" },
        { source_id: b, amount_minor_units: 800_000, currency: "VND", note: "BOOM" }
      ])

      expect(response).to have_http_status(:unprocessable_entity)
      expect(alice.transactions.where(kind: "adjustment").count).to eq(0)
    end
  end

  describe "validation and authorization" do
    it "rejects a source owned by another user with 422 and writes nothing" do
      bob_acct = vnd_account(bob, opening: 1_000_000)

      reconcile(alice, [ { source_id: bob_acct, amount_minor_units: 5, currency: "VND" } ])

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
      expect(Transaction.count).to eq(0)
    end

    it "rejects reconciling a Holding (no money balance) with 422" do
      holding = create_source(alice, { kind: "holding", name: "VNM", opening_quantity: "10",
                                       unit: "shares", ticker: "VNM" })

      reconcile(alice, [ { source_id: holding, amount_minor_units: 1, currency: "VND" } ])

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects a balance whose currency differs from the source with 422" do
      acct = vnd_account(alice, opening: 1_000_000)

      reconcile(alice, [ { source_id: acct, amount_minor_units: 100, currency: "SGD" } ])

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects an empty balances list with 422" do
      reconcile(alice, [])

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects an unauthenticated request" do
      post "/api/reconciliations",
           params: { balances: [ { source_id: 1, amount_minor_units: 1, currency: "VND" } ] }.to_json,
           headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
    end
  end
end

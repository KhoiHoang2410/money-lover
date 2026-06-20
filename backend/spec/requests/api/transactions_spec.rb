require "rails_helper"

# Transactions CRUD (issue 14): tenant-scoped create/read/update/delete across
# all kinds (expense, income, transfer, invest, adjustment). The security
# properties are authorization (cross-user 404), validation (422) and the
# money-correctness invariants: each kind posts the balance BalanceEngine would
# compute, a backfill leaves the current balance unchanged, a cross-currency fee
# is exact, and an oversell is rejected atomically. Every response is asserted
# against the OpenAPI contract (ADR-0017).
RSpec.describe "Api::Transactions", type: :request do
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

  def create_txn(user, body)
    post "/api/transactions", params: body.to_json, headers: auth_headers(user, body: true)
  end

  def balance_of(user, source_id)
    get "/api/sources/#{source_id}", headers: auth_headers(user)
    response.parsed_body["current_balance"]["amount_minor"]
  end

  def vnd_account(user, opening: 0, name: "VPBank")
    create_source(user, { kind: "account", name: name, currency: "VND", opening_minor_units: opening })
  end

  describe "POST /api/transactions per kind (balances match BalanceEngine)" do
    it "posts an expense that reduces the source account" do
      acct = vnd_account(alice, opening: 1_000_000)

      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 250_000,
                          currency: "VND", note: "Lunch" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(response.parsed_body).to include("kind" => "expense", "source_id" => acct)
      expect(response.parsed_body["amount"]).to eq("amount_minor" => 250_000, "currency" => "VND")
      expect(balance_of(alice, acct)).to eq(750_000)
    end

    it "posts an income that increases the source account" do
      acct = vnd_account(alice, opening: 1_000_000)

      create_txn(alice, { kind: "income", source_id: acct, amount_minor_units: 500_000, currency: "VND" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(balance_of(alice, acct)).to eq(1_500_000)
    end

    it "posts a credit-card expense that grows the liability (more negative)" do
      card = create_source(alice, { kind: "credit_card", name: "VIB", currency: "VND",
                                    opening_minor_units: -100_000 })

      create_txn(alice, { kind: "expense", source_id: card, amount_minor_units: 400_000, currency: "VND" })

      expect(response).to have_http_status(:created)
      expect(balance_of(alice, card)).to eq(-500_000)
    end

    it "posts a same-currency transfer that moves money between two accounts" do
      from = vnd_account(alice, opening: 1_000_000, name: "From")
      to   = vnd_account(alice, opening: 0, name: "To")

      create_txn(alice, { kind: "transfer", source_id: from, destination_id: to,
                          amount_minor_units: 300_000, currency: "VND" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(balance_of(alice, from)).to eq(700_000)
      expect(balance_of(alice, to)).to eq(300_000)
    end

    it "posts a signed adjustment directly onto the source" do
      acct = vnd_account(alice, opening: 1_000_000)

      create_txn(alice, { kind: "adjustment", source_id: acct, amount_minor_units: -75_000,
                          currency: "VND", note: "Reconcile" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(balance_of(alice, acct)).to eq(925_000)
    end
  end

  describe "cross-currency transfer (fee via TransferFxMath)" do
    it "computes the fee as (amount_out × rate) − amount_in in the destination currency" do
      sgd = create_source(alice, { kind: "account", name: "Wise SGD", currency: "SGD",
                                   opening_minor_units: 50_000 }) # 500.00 SGD
      vnd = vnd_account(alice, opening: 0, name: "VPBank")

      create_txn(alice, { kind: "transfer", source_id: sgd, destination_id: vnd,
                          amount_minor_units: 10_000, currency: "SGD",     # 100.00 SGD out
                          destination_amount_minor_units: 1_690_000, destination_currency: "VND",
                          manual_rate: "17000" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      # (100 × 17000) − 1,690,000 = 10,000 VND.
      expect(body["fee"]).to eq("amount_minor" => 10_000, "currency" => "VND")
      expect(body["destination_amount"]).to eq("amount_minor" => 1_690_000, "currency" => "VND")
      expect(body["manual_rate"]).to eq("17000")
      expect(balance_of(alice, sgd)).to eq(40_000)
      expect(balance_of(alice, vnd)).to eq(1_690_000)
    end

    it "rejects a cross-currency transfer missing its manual rate with 422" do
      sgd = create_source(alice, { kind: "account", name: "Wise SGD", currency: "SGD",
                                   opening_minor_units: 50_000 })
      vnd = vnd_account(alice, opening: 0)

      create_txn(alice, { kind: "transfer", source_id: sgd, destination_id: vnd,
                          amount_minor_units: 10_000, currency: "SGD",
                          destination_amount_minor_units: 1_690_000, destination_currency: "VND" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end
  end

  describe "invest (oversell guard + VND-only)" do
    def holding(user, qty: "10")
      create_source(user, { kind: "holding", name: "VNM", opening_quantity: qty,
                            unit: "shares", ticker: "VNM" })
    end

    it "posts a buy that debits the account" do
      acct = vnd_account(alice, opening: 5_000_000)
      h = holding(alice)

      create_txn(alice, { kind: "invest", source_id: acct, destination_id: h,
                          amount_minor_units: 1_200_000, currency: "VND",
                          trade_quantity: "20", trade_direction: "buy" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(response.parsed_body["trade_quantity"]).to eq("20")
      expect(balance_of(alice, acct)).to eq(3_800_000)
    end

    it "posts a sell within the held quantity and credits the account" do
      acct = vnd_account(alice, opening: 0)
      h = holding(alice, qty: "10")

      create_txn(alice, { kind: "invest", source_id: acct, destination_id: h,
                          amount_minor_units: 600_000, currency: "VND",
                          trade_quantity: "10", trade_direction: "sell" })

      expect(response).to have_http_status(:created)
      expect(balance_of(alice, acct)).to eq(600_000)
    end

    it "rejects an oversell atomically (no row written)" do
      acct = vnd_account(alice, opening: 0)
      h = holding(alice, qty: "10")

      create_txn(alice, { kind: "invest", source_id: acct, destination_id: h,
                          amount_minor_units: 900_000, currency: "VND",
                          trade_quantity: "15", trade_direction: "sell" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(alice.transactions.count).to eq(0)
    end

    it "blocks a sell that exceeds the running quantity after a prior sell" do
      acct = vnd_account(alice, opening: 0)
      h = holding(alice, qty: "10")

      create_txn(alice, { kind: "invest", source_id: acct, destination_id: h,
                          amount_minor_units: 400_000, currency: "VND",
                          trade_quantity: "8", trade_direction: "sell" })
      expect(response).to have_http_status(:created)

      create_txn(alice, { kind: "invest", source_id: acct, destination_id: h,
                          amount_minor_units: 200_000, currency: "VND",
                          trade_quantity: "5", trade_direction: "sell" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(alice.transactions.count).to eq(1)
    end

    it "rejects a non-VND invest with 422" do
      acct = create_source(alice, { kind: "account", name: "Wise SGD", currency: "SGD",
                                    opening_minor_units: 0 })
      h = holding(alice)

      create_txn(alice, { kind: "invest", source_id: acct, destination_id: h,
                          amount_minor_units: 1_000, currency: "SGD",
                          trade_quantity: "1", trade_direction: "buy" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end
  end

  describe "backfill (current balance unchanged, appears in history)" do
    it "restates the source opening balance so the current balance is unchanged" do
      acct = vnd_account(alice, opening: 1_000_000)

      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 200_000,
                          currency: "VND", backfill: true })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(response.parsed_body["backfill"]).to be(true)
      # Current balance unchanged; the opening was restated upward by the offset.
      expect(balance_of(alice, acct)).to eq(1_000_000)
      expect(Source.find(acct).opening_minor_units).to eq(1_200_000)
      # Still shows in history.
      get "/api/transactions", headers: auth_headers(alice)
      expect(response.parsed_body["transactions"].size).to eq(1)
    end
  end

  describe "GET /api/transactions (filters)" do
    it "lists only the caller's transactions, newest first" do
      acct = vnd_account(alice, opening: 1_000_000)
      bob_acct = vnd_account(bob, opening: 1_000_000)
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 1, currency: "VND",
                          occurred_on: "2026-01-01" })
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 2, currency: "VND",
                          occurred_on: "2026-03-01" })
      create_txn(bob, { kind: "expense", source_id: bob_acct, amount_minor_units: 9, currency: "VND" })

      get "/api/transactions", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      amounts = response.parsed_body["transactions"].map { |t| t["amount"]["amount_minor"] }
      expect(amounts).to eq([ 2, 1 ])
    end

    it "filters by kind, date range and source" do
      acct = vnd_account(alice, opening: 1_000_000, name: "A")
      other = vnd_account(alice, opening: 1_000_000, name: "B")
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 10, currency: "VND",
                          occurred_on: "2026-02-10" })
      create_txn(alice, { kind: "income", source_id: acct, amount_minor_units: 20, currency: "VND",
                          occurred_on: "2026-02-20" })
      create_txn(alice, { kind: "expense", source_id: other, amount_minor_units: 30, currency: "VND",
                          occurred_on: "2026-05-01" })

      get "/api/transactions?kind=expense", headers: auth_headers(alice)
      expect(response.parsed_body["transactions"].map { |t| t["kind"] }.uniq).to eq([ "expense" ])

      get "/api/transactions?from=2026-02-01&to=2026-02-28", headers: auth_headers(alice)
      expect(response.parsed_body["transactions"].size).to eq(2)

      get "/api/transactions?source_id=#{other}", headers: auth_headers(alice)
      amounts = response.parsed_body["transactions"].map { |t| t["amount"]["amount_minor"] }
      expect(amounts).to eq([ 30 ])
    end

    it "matches a transfer when filtering by either leg" do
      from = vnd_account(alice, opening: 1_000_000, name: "From")
      to   = vnd_account(alice, opening: 0, name: "To")
      create_txn(alice, { kind: "transfer", source_id: from, destination_id: to,
                          amount_minor_units: 100, currency: "VND" })

      get "/api/transactions?source_id=#{to}", headers: auth_headers(alice)
      expect(response.parsed_body["transactions"].size).to eq(1)
    end
  end

  describe "GET /api/transactions/:id" do
    it "reads the caller's own transaction" do
      acct = vnd_account(alice, opening: 1_000_000)
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 5, currency: "VND" })
      id = response.parsed_body["id"]

      get "/api/transactions/#{id}", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["id"]).to eq(id)
    end

    it "returns 404 for another user's transaction" do
      acct = vnd_account(bob, opening: 1_000_000)
      create_txn(bob, { kind: "expense", source_id: acct, amount_minor_units: 5, currency: "VND",
                        note: "Bob Secret" })
      bob_id = response.parsed_body["id"]

      get "/api/transactions/#{bob_id}", headers: auth_headers(alice)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
      expect(response.body).not_to include("Bob Secret")
    end
  end

  describe "PATCH /api/transactions/:id" do
    it "updates an amount and recomputes the balance" do
      acct = vnd_account(alice, opening: 1_000_000)
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 200_000, currency: "VND" })
      id = response.parsed_body["id"]

      patch "/api/transactions/#{id}", params: { amount_minor_units: 300_000, note: "Edited" }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["note"]).to eq("Edited")
      expect(balance_of(alice, acct)).to eq(700_000)
    end

    it "returns 404 when updating another user's transaction" do
      acct = vnd_account(bob, opening: 1_000_000)
      create_txn(bob, { kind: "expense", source_id: acct, amount_minor_units: 5, currency: "VND" })
      bob_id = response.parsed_body["id"]

      patch "/api/transactions/#{bob_id}", params: { note: "Hacked" }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
    end
  end

  describe "DELETE /api/transactions/:id" do
    it "deletes the caller's transaction and restores the balance" do
      acct = vnd_account(alice, opening: 1_000_000)
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 200_000, currency: "VND" })
      id = response.parsed_body["id"]

      delete "/api/transactions/#{id}", headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:no_content)
      expect(Transaction.exists?(id)).to be(false)
      expect(balance_of(alice, acct)).to eq(1_000_000)
    end
  end

  describe "validation and authorization" do
    it "rejects an unknown kind with a structured 422" do
      acct = vnd_account(alice, opening: 0)
      create_txn(alice, { kind: "gift", source_id: acct, amount_minor_units: 1, currency: "VND" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end

    it "rejects a transaction referencing another user's source with 422" do
      bob_acct = vnd_account(bob, opening: 0)
      create_txn(alice, { kind: "expense", source_id: bob_acct, amount_minor_units: 1, currency: "VND" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects an unauthenticated request" do
      post "/api/transactions",
           params: { kind: "expense", source_id: 1, amount_minor_units: 1, currency: "VND" }.to_json,
           headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
    end
  end

  describe "source delete integrity (issue 13 guard, now real)" do
    it "blocks deleting a source referenced by a transaction with 409" do
      acct = vnd_account(alice, opening: 1_000_000)
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 1, currency: "VND" })

      delete "/api/sources/#{acct}", headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:conflict)
      assert_conforms_to_contract(409)
      expect(Source.exists?(acct)).to be(true)
    end
  end
end

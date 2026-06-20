require "rails_helper"

# Sources CRUD (issue 13): tenant-scoped create/read/update/delete for Accounts,
# Credit cards and Holdings, each returning a live current balance + base-currency
# valuation. Authorization (cross-user 404) and validation (422) are the security
# properties; every response is asserted against the OpenAPI contract (ADR-0017).
RSpec.describe "Api::Sources", type: :request do
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
  end

  describe "POST /api/sources" do
    it "creates a VND account with an opening balance" do
      create_source(alice, { kind: "account", name: "VPBank", icon: "bank",
                             currency: "VND", opening_minor_units: 1_000_000 })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body["kind"]).to eq("account")
      expect(body["name"]).to eq("VPBank")
      expect(body["opening_balance"]).to eq("amount_minor" => 1_000_000, "currency" => "VND")
      expect(body["current_balance"]).to eq("amount_minor" => 1_000_000, "currency" => "VND")
      expect(body["valuation"]).to eq("amount_minor" => 1_000_000, "currency" => "VND")
      expect(body).not_to have_key("holding")
    end

    it "creates a credit card as a (negative) liability" do
      create_source(alice, { kind: "credit_card", name: "VIB Card",
                             currency: "VND", opening_minor_units: -500_000 })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(response.parsed_body["current_balance"]["amount_minor"]).to eq(-500_000)
    end

    it "creates a gold holding from an opening quantity (no money amount)" do
      create_source(alice, { kind: "holding", name: "SJC Gold",
                             opening_quantity: "3", unit: "chi" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body["kind"]).to eq("holding")
      expect(body["holding"]).to eq("opening_quantity" => "3", "unit" => "chi", "ticker" => nil)
      expect(body).not_to have_key("opening_balance")
      # No rate table yet (issue 19) → valuation degrades to ₫0, never raising.
      expect(body["valuation"]).to eq("amount_minor" => 0, "currency" => "VND")
    end

    it "creates a stock holding with a ticker" do
      create_source(alice, { kind: "holding", name: "VNM Shares",
                             opening_quantity: "120", unit: "shares", ticker: "VNM" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      expect(response.parsed_body["holding"]).to eq(
        "opening_quantity" => "120", "unit" => "shares", "ticker" => "VNM"
      )
    end

    it "rejects an unknown kind with a structured 422" do
      create_source(alice, { kind: "wallet", name: "Nope" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end

    it "rejects an account without a currency/opening balance with 422" do
      create_source(alice, { kind: "account", name: "Cash" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects a stock holding missing its ticker with 422" do
      create_source(alice, { kind: "holding", name: "Mystery",
                             opening_quantity: "10", unit: "shares" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects a gold holding carrying a ticker with 422" do
      create_source(alice, { kind: "holding", name: "Gold", opening_quantity: "1",
                             unit: "chi", ticker: "VNM" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects an unauthenticated request" do
      post "/api/sources", params: { kind: "account", name: "X", currency: "VND",
                                     opening_minor_units: 1 }.to_json,
           headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
    end
  end

  describe "GET /api/sources" do
    it "lists only the caller's sources with balances and valuations" do
      create_source(alice, { kind: "account", name: "VPBank", currency: "VND",
                             opening_minor_units: 1_000_000 })
      create_source(bob, { kind: "account", name: "Bob Bank", currency: "VND",
                          opening_minor_units: 9_999 })

      get "/api/sources", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      names = response.parsed_body["sources"].map { |s| s["name"] }
      expect(names).to eq([ "VPBank" ])
      expect(response.body).not_to include("Bob Bank")
    end
  end

  describe "GET /api/sources/:id" do
    it "reads the caller's own source" do
      create_source(alice, { kind: "account", name: "VPBank", currency: "VND",
                             opening_minor_units: 1_000_000 })
      id = response.parsed_body["id"]

      get "/api/sources/#{id}", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["id"]).to eq(id)
    end

    it "returns 404 (not the row) for another user's source" do
      create_source(bob, { kind: "account", name: "Bob Secret", currency: "VND",
                          opening_minor_units: 1 })
      bob_id = response.parsed_body["id"]

      get "/api/sources/#{bob_id}", headers: auth_headers(alice)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
      expect(response.body).not_to include("Bob Secret")
    end
  end

  describe "PATCH /api/sources/:id" do
    it "updates a source's name and opening balance" do
      create_source(alice, { kind: "account", name: "VPBank", currency: "VND",
                             opening_minor_units: 1_000_000 })
      id = response.parsed_body["id"]

      patch "/api/sources/#{id}",
            params: { name: "VPBank Main", opening_minor_units: 2_000_000 }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      body = response.parsed_body
      expect(body["name"]).to eq("VPBank Main")
      expect(body["current_balance"]["amount_minor"]).to eq(2_000_000)
    end

    it "rejects an invalid currency with 422" do
      create_source(alice, { kind: "account", name: "VPBank", currency: "VND",
                             opening_minor_units: 1 })
      id = response.parsed_body["id"]

      patch "/api/sources/#{id}", params: { currency: "GBP" }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "returns 404 when updating another user's source" do
      create_source(bob, { kind: "account", name: "Bob", currency: "VND",
                          opening_minor_units: 1 })
      bob_id = response.parsed_body["id"]

      patch "/api/sources/#{bob_id}", params: { name: "Hacked" }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
    end
  end

  describe "DELETE /api/sources/:id" do
    it "deletes the caller's source" do
      create_source(alice, { kind: "account", name: "VPBank", currency: "VND",
                             opening_minor_units: 1 })
      id = response.parsed_body["id"]

      delete "/api/sources/#{id}", headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:no_content)
      expect(Source.exists?(id)).to be(false)
    end

    it "blocks deletion with 409 when the source is referenced by transactions" do
      create_source(alice, { kind: "account", name: "VPBank", currency: "VND",
                             opening_minor_units: 1 })
      id = response.parsed_body["id"]
      # The Transactions ledger (issue 14) is the future referencer; simulate one
      # to prove the delete-integrity guard returns a contract-conformant 409.
      allow_any_instance_of(Source).to receive(:referenced_by_transactions?).and_return(true)

      delete "/api/sources/#{id}", headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:conflict)
      assert_conforms_to_contract(409)
      expect(response.parsed_body.dig("error", "code")).to eq("conflict")
      expect(Source.exists?(id)).to be(true)
    end

    it "returns 404 when deleting another user's source" do
      create_source(bob, { kind: "account", name: "Bob", currency: "VND",
                          opening_minor_units: 1 })
      bob_id = response.parsed_body["id"]

      delete "/api/sources/#{bob_id}", headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
    end
  end
end

require "rails_helper"

# Net worth & report-data API (issue 18): read-only aggregates derived on read by
# the pure engines (NetWorthEngine / BudgetEngine / GoalTracker), all in the base
# currency VND. The security properties are authentication (401) and tenant
# isolation (a caller only ever sees their own rows); the money-correctness
# properties are that net worth matches NetWorthEngine, a Contribution leaves net
# unchanged, and each report aggregate is correct over a known dataset and date
# range. Every response is asserted against the OpenAPI contract (ADR-0017).
RSpec.describe "Api::Reports", type: :request do
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
    response.parsed_body["id"]
  end

  def create_envelope(user, body)
    post "/api/envelopes", params: body.to_json, headers: auth_headers(user, body: true)
    response.parsed_body["id"]
  end

  def create_goal(user, body)
    post "/api/goals", params: body.to_json, headers: auth_headers(user, body: true)
    response.parsed_body["id"]
  end

  def vnd_account(user, opening: 0, name: "VPBank")
    create_source(user, { kind: "account", name: name, currency: "VND", opening_minor_units: opening })
  end

  describe "GET /api/net_worth" do
    it "returns asset / debt / net matching the NetWorth engine" do
      acct = vnd_account(alice, opening: 1_000_000)
      create_source(alice, { kind: "credit_card", name: "VIB", currency: "VND", opening_minor_units: -300_000 })
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 200_000, currency: "VND" })

      get "/api/net_worth", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      body = response.parsed_body
      expect(body["asset"]).to eq("amount_minor" => 800_000, "currency" => "VND")
      expect(body["debt"]).to eq("amount_minor" => -300_000, "currency" => "VND")
      expect(body["net"]).to eq("amount_minor" => 500_000, "currency" => "VND")
    end

    it "counts a Goal balance as an Asset and leaves net unchanged after a Contribution" do
      acct = vnd_account(alice, opening: 1_000_000)
      goal = create_goal(alice, {
        name: "Laptop", target_minor_units: 2_000_000,
        schedule: [ { year: 2026, month: 1, amount_minor_units: 2_000_000 } ]
      })

      get "/api/net_worth", headers: auth_headers(alice)
      net_before = response.parsed_body["net"]

      post "/api/goals/#{goal}/contributions",
           params: { source_id: acct, amount_minor_units: 400_000, currency: "VND" }.to_json,
           headers: auth_headers(alice, body: true)

      get "/api/net_worth", headers: auth_headers(alice)
      body = response.parsed_body
      expect(body["asset"]).to eq("amount_minor" => 1_000_000, "currency" => "VND")
      expect(body["net"]).to eq(net_before)
    end

    it "is zero for a fresh user and isolated per tenant" do
      vnd_account(alice, opening: 5_000_000)

      get "/api/net_worth", headers: auth_headers(bob)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["net"]).to eq("amount_minor" => 0, "currency" => "VND")
    end

    it "rejects an unauthenticated request" do
      get "/api/net_worth", headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
    end
  end

  describe "GET /api/reports/spending_trends" do
    it "sums expenses per month and zero-fills every month in the range" do
      acct = vnd_account(alice, opening: 10_000_000)
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 200_000,
                          currency: "VND", occurred_on: "2026-01-10" })
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 50_000,
                          currency: "VND", occurred_on: "2026-01-20" })
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 100_000,
                          currency: "VND", occurred_on: "2026-03-05" })

      get "/api/reports/spending_trends", params: { from: "2026-01-01", to: "2026-03-31" },
          headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      months = response.parsed_body["months"]
      expect(months.map { |m| m["month"] }).to eq(%w[2026-01 2026-02 2026-03])
      expect(months[0]["spent"]).to eq("amount_minor" => 250_000, "currency" => "VND")
      expect(months[1]["spent"]).to eq("amount_minor" => 0, "currency" => "VND")
      expect(months[2]["spent"]).to eq("amount_minor" => 100_000, "currency" => "VND")
    end

    it "rejects an inverted range with 422" do
      get "/api/reports/spending_trends", params: { from: "2026-03-01", to: "2026-01-01" },
          headers: auth_headers(alice)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end
  end

  describe "GET /api/reports/envelope_distribution" do
    it "returns per-envelope spent for the requested month" do
      acct = vnd_account(alice, opening: 10_000_000)
      food = create_envelope(alice, { name: "Food", allocation_minor_units: 2_000_000 })
      fun  = create_envelope(alice, { name: "Fun", allocation_minor_units: 1_000_000 })
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 300_000,
                          currency: "VND", envelope_id: food, occurred_on: "2026-02-10" })
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 120_000,
                          currency: "VND", envelope_id: fun, occurred_on: "2026-02-15" })
      # Out-of-month expense must not count.
      create_txn(alice, { kind: "expense", source_id: acct, amount_minor_units: 999_000,
                          currency: "VND", envelope_id: food, occurred_on: "2026-03-01" })

      get "/api/reports/envelope_distribution", params: { month: "2026-02" }, headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      body = response.parsed_body
      expect(body["month"]).to eq("2026-02")
      spent = body["envelopes"].to_h { |e| [ e["name"], e["spent"]["amount_minor"] ] }
      expect(spent).to eq("Food" => 300_000, "Fun" => 120_000)
      expect(body["total"]).to eq("amount_minor" => 420_000, "currency" => "VND")
    end

    it "rejects a malformed month with 422" do
      get "/api/reports/envelope_distribution", params: { month: "2026/02" }, headers: auth_headers(alice)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end
  end

  describe "GET /api/reports/goal_progress" do
    it "returns each goal's balance, target and expected" do
      acct = vnd_account(alice, opening: 10_000_000)
      goal = create_goal(alice, {
        name: "Laptop", target_minor_units: 2_000_000,
        schedule: [ { year: 2026, month: 1, amount_minor_units: 1_000_000 } ]
      })
      post "/api/goals/#{goal}/contributions",
           params: { source_id: acct, amount_minor_units: 500_000, currency: "VND" }.to_json,
           headers: auth_headers(alice, body: true)

      get "/api/reports/goal_progress", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      line = response.parsed_body["goals"].first
      expect(line["name"]).to eq("Laptop")
      expect(line["balance"]).to eq("amount_minor" => 500_000, "currency" => "VND")
      expect(line["target"]).to eq("amount_minor" => 2_000_000, "currency" => "VND")
    end
  end

  describe "GET /api/reports/net_worth_history" do
    it "returns net worth at each month-end over the range" do
      acct = vnd_account(alice, opening: 1_000_000)
      create_txn(alice, { kind: "income", source_id: acct, amount_minor_units: 500_000,
                          currency: "VND", occurred_on: "2026-02-15" })

      get "/api/reports/net_worth_history", params: { from: "2026-01-01", to: "2026-03-31" },
          headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      points = response.parsed_body["points"]
      expect(points.map { |p| p["month"] }).to eq(%w[2026-01 2026-02 2026-03])
      expect(points[0]["net"]).to eq("amount_minor" => 1_000_000, "currency" => "VND")
      expect(points[1]["net"]).to eq("amount_minor" => 1_500_000, "currency" => "VND")
      expect(points[2]["net"]).to eq("amount_minor" => 1_500_000, "currency" => "VND")
    end
  end
end

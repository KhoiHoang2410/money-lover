require "rails_helper"

# Goals CRUD + the Contribution action (issue 16). The security properties are
# authorization (cross-user 404), validation (422) and the money-correctness
# invariants from CONTEXT.md / ADR-0007: a Goal read reports the balance and
# per-line status/shortfall the pure GoalTracker engine computes; a Contribution
# moves real money atomically from a VND Account into the Goal and leaves net
# worth unchanged (one Asset becomes another); foreign-currency funding is
# rejected. Every response is asserted against the OpenAPI contract (ADR-0017).
RSpec.describe "Api::Goals", type: :request do
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

  def vnd_account(user, opening: 0, name: "VPBank")
    create_source(user, { kind: "account", name: name, currency: "VND", opening_minor_units: opening })
  end

  def balance_of(user, source_id)
    get "/api/sources/#{source_id}", headers: auth_headers(user)
    response.parsed_body["current_balance"]["amount_minor"]
  end

  # A House goal with a discontinuous Schedule, all lines far in the past/future
  # so per-line status is deterministic regardless of when the suite runs. Months
  # are distinct numbers (1, 2, 3) — GoalTracker keys status/shortfall by month.
  def house_goal_body
    {
      name: "House",
      icon: "house",
      target_minor_units: 400_000_000,
      currency: "VND",
      start_month: { year: 2020, month: 1 },
      end_month: { year: 2100, month: 3 },
      schedule: [
        { year: 2020, month: 1, amount_minor_units: 100_000_000 },
        { year: 2020, month: 2, amount_minor_units: 100_000_000 },
        { year: 2100, month: 3, amount_minor_units: 150_000_000 }
      ]
    }
  end

  def create_goal(user, body = house_goal_body)
    post "/api/goals", params: body.to_json, headers: auth_headers(user, body: true)
    response.parsed_body["id"]
  end

  def contribute(user, goal_id, body)
    post "/api/goals/#{goal_id}/contributions", params: body.to_json, headers: auth_headers(user, body: true)
  end

  describe "POST /api/goals" do
    it "creates a goal with target, window and schedule" do
      create_goal(alice)

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body).to include("name" => "House", "currency" => "VND")
      expect(body["target"]).to eq("amount_minor" => 400_000_000, "currency" => "VND")
      expect(body["balance"]).to eq("amount_minor" => 0, "currency" => "VND")
      expect(body["start_month"]).to eq("year" => 2020, "month" => 1)
      expect(body["schedule"].size).to eq(3)
    end

    it "rejects a goal with no name (422)" do
      post "/api/goals", params: { target_minor_units: 1, schedule: [] }.to_json,
           headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end

    it "rejects a non-positive target (422)" do
      post "/api/goals",
           params: house_goal_body.merge(target_minor_units: 0).to_json,
           headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects a non-VND goal (422)" do
      post "/api/goals", params: house_goal_body.merge(currency: "USD").to_json,
           headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects an unauthenticated request (401)" do
      post "/api/goals", params: house_goal_body.to_json,
           headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
    end
  end

  describe "GET /api/goals" do
    it "lists only the caller's goals" do
      create_goal(alice)
      create_goal(bob)

      get "/api/goals", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["goals"].size).to eq(1)
    end
  end

  describe "GET /api/goals/:id" do
    it "returns 404 for another user's goal" do
      bob_goal = create_goal(bob)

      get "/api/goals/#{bob_goal}", headers: auth_headers(alice)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
    end
  end

  describe "PATCH /api/goals/:id" do
    it "updates the name and target" do
      goal = create_goal(alice)

      patch "/api/goals/#{goal}",
            params: { name: "Bigger House", target_minor_units: 500_000_000 }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["name"]).to eq("Bigger House")
      expect(response.parsed_body["target"]).to eq("amount_minor" => 500_000_000, "currency" => "VND")
    end

    it "returns 404 updating another user's goal" do
      bob_goal = create_goal(bob)

      patch "/api/goals/#{bob_goal}", params: { name: "Hacked" }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
    end
  end

  describe "DELETE /api/goals/:id" do
    it "deletes the caller's goal" do
      goal = create_goal(alice)

      delete "/api/goals/#{goal}", headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:no_content)
      expect(GoalRecord.exists?(goal)).to be(false)
    end
  end

  describe "POST /api/goals/:id/contributions (funds atomically, net worth unchanged)" do
    it "debits the account and credits the goal by the same amount" do
      acct = vnd_account(alice, opening: 10_000_000)
      goal = create_goal(alice)
      before_net = balance_of(alice, acct) # only Asset so far (goal balance 0)

      contribute(alice, goal, { source_id: acct, amount_minor_units: 4_000_000 })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      goal_balance = response.parsed_body["balance"]["amount_minor"]
      expect(goal_balance).to eq(4_000_000)
      expect(balance_of(alice, acct)).to eq(6_000_000)
      # Net worth = Σ Asset balances. The Account dropped by exactly what the Goal
      # gained, so net is unchanged (ADR-0007).
      expect(balance_of(alice, acct) + goal_balance).to eq(before_net)
    end

    it "rejects funding from a foreign-currency account (422)" do
      sgd = create_source(alice, { kind: "account", name: "Wise SGD", currency: "SGD",
                                   opening_minor_units: 50_000 })
      goal = create_goal(alice)

      contribute(alice, goal, { source_id: sgd, amount_minor_units: 1_000, currency: "SGD" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(alice.transactions.count).to eq(0)
    end

    it "rejects a non-positive amount (422)" do
      acct = vnd_account(alice, opening: 10_000_000)
      goal = create_goal(alice)

      contribute(alice, goal, { source_id: acct, amount_minor_units: 0 })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects funding another user's source with 422" do
      bob_acct = vnd_account(bob, opening: 10_000_000)
      goal = create_goal(alice)

      contribute(alice, goal, { source_id: bob_acct, amount_minor_units: 1_000 })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "returns 404 contributing to another user's goal" do
      acct = vnd_account(alice, opening: 10_000_000)
      bob_goal = create_goal(bob)

      contribute(alice, bob_goal, { source_id: acct, amount_minor_units: 1_000 })

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
    end
  end

  describe "GoalTracker status + shortfall correctness" do
    it "reports per-line status and shortfall against the contributed total" do
      acct = vnd_account(alice, opening: 1_000_000_000)
      goal = create_goal(alice)

      # Contribute 150M total: fills 2020/1 (100M) fully, 2020/2 (100M) half.
      contribute(alice, goal, { source_id: acct, amount_minor_units: 150_000_000 })
      expect(response).to have_http_status(:created)

      get "/api/goals/#{goal}", headers: auth_headers(alice)
      assert_conforms_to_contract(200)
      body = response.parsed_body

      expect(body["balance"]).to eq("amount_minor" => 150_000_000, "currency" => "VND")

      funded_2020 = body["schedule"].find { |l| l["year"] == 2020 && l["month"] == 1 }
      missed_2020 = body["schedule"].find { |l| l["year"] == 2020 && l["month"] == 2 }
      pending_2100 = body["schedule"].find { |l| l["year"] == 2100 && l["month"] == 3 }

      expect(funded_2020["status"]).to eq("funded")
      expect(funded_2020["shortfall"]).to eq("amount_minor" => 0, "currency" => "VND")

      expect(missed_2020["status"]).to eq("missed")
      expect(missed_2020["shortfall"]).to eq("amount_minor" => 50_000_000, "currency" => "VND")

      expect(pending_2100["status"]).to eq("pending")
      expect(pending_2100["shortfall"]).to eq("amount_minor" => 150_000_000, "currency" => "VND")

      # Expected-by-today = 2020/1 + 2020/2 = 200M (2100 is future); actual 150M
      # trails, so the goal is behind plan.
      expect(body["progress"]["expected"]).to eq("amount_minor" => 200_000_000, "currency" => "VND")
      expect(body["progress"]["pct_sign"]).to eq("negative")
    end
  end
end

require "rails_helper"

# Envelopes API (issue 15): tenant-scoped CRUD for budgeting Envelopes, plus the
# two seeding actions (starter envelopes, allocation template) and per-month
# spent/remaining computed by BudgetEngine. The security properties are
# authorization (cross-user 404) and validation (422); the money-correctness
# properties are the exactly-one-Reserve invariant, idempotent starter seeding,
# and correct per-month allocation/spent/remaining. Every response is asserted
# against the OpenAPI contract (ADR-0017).
RSpec.describe "Api::Envelopes", type: :request do
  let(:alice) { Auth::PasswordProvider.register(username: "alice", password: "secret123") }
  let(:bob)   { Auth::PasswordProvider.register(username: "bob",   password: "secret123") }

  def auth_headers(user, body: false)
    headers = { "Accept" => "application/json" }
    headers["Content-Type"] = "application/json" if body
    headers["Authorization"] = "Bearer #{Auth::TokenService.issue_access_token(user)}" if user
    headers
  end

  def create_envelope(user, body)
    post "/api/envelopes", params: body.to_json, headers: auth_headers(user, body: true)
  end

  def vnd_account(user, opening: 0, name: "VPBank")
    post "/api/sources", params: { kind: "account", name: name, currency: "VND",
                                   opening_minor_units: opening }.to_json,
         headers: auth_headers(user, body: true)
    response.parsed_body["id"]
  end

  describe "POST /api/envelopes" do
    it "creates an envelope with a name, icon and allocation" do
      create_envelope(alice, { name: "Food", icon: "fork.knife", allocation_minor_units: 2_000_000 })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body["name"]).to eq("Food")
      expect(body["is_reserve"]).to be(false)
      expect(body["allocation"]).to eq("amount_minor" => 2_000_000, "currency" => "VND")
      expect(body["spent"]).to eq("amount_minor" => 0, "currency" => "VND")
      expect(body["remaining"]).to eq("amount_minor" => 2_000_000, "currency" => "VND")
      expect(body).not_to have_key("weekly_cap")
    end

    it "creates a reserve envelope and includes optional caps" do
      create_envelope(alice, { name: "Reserve", is_reserve: true,
                               weekly_cap_minor_units: 500_000, monthly_cap_minor_units: 2_000_000 })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body["is_reserve"]).to be(true)
      expect(body["weekly_cap"]).to eq("amount_minor" => 500_000, "currency" => "VND")
      expect(body["monthly_cap"]).to eq("amount_minor" => 2_000_000, "currency" => "VND")
    end

    it "rejects a blank name with a structured 422" do
      create_envelope(alice, { allocation_minor_units: 1 })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end

    it "rejects a negative allocation with 422" do
      create_envelope(alice, { name: "Food", allocation_minor_units: -1 })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects an unauthenticated request" do
      post "/api/envelopes", params: { name: "Food" }.to_json,
           headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
    end
  end

  describe "exactly-one-Reserve invariant" do
    it "rejects a second reserve with 422" do
      create_envelope(alice, { name: "Reserve", is_reserve: true })
      expect(response).to have_http_status(:created)

      create_envelope(alice, { name: "Backup", is_reserve: true })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "lets a different user have their own reserve" do
      create_envelope(alice, { name: "Reserve", is_reserve: true })
      create_envelope(bob, { name: "Reserve", is_reserve: true })

      expect(response).to have_http_status(:created)
    end

    it "rejects promoting a second envelope to reserve via PATCH with 422" do
      create_envelope(alice, { name: "Reserve", is_reserve: true })
      create_envelope(alice, { name: "Food" })
      food_id = response.parsed_body["id"]

      patch "/api/envelopes/#{food_id}", params: { is_reserve: true }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end
  end

  describe "GET /api/envelopes" do
    it "lists only the caller's envelopes" do
      create_envelope(alice, { name: "Food" })
      create_envelope(bob, { name: "Bob Bucket" })

      get "/api/envelopes", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      names = response.parsed_body["envelopes"].map { |e| e["name"] }
      expect(names).to eq([ "Food" ])
      expect(response.body).not_to include("Bob Bucket")
    end

    it "reflects this month's expenses in spent and remaining" do
      acct = vnd_account(alice, opening: 5_000_000)
      create_envelope(alice, { name: "Food", allocation_minor_units: 2_000_000 })
      env_id = response.parsed_body["id"]

      post "/api/transactions", params: { kind: "expense", source_id: acct, envelope_id: env_id,
                                          amount_minor_units: 300_000, currency: "VND" }.to_json,
           headers: auth_headers(alice, body: true)
      expect(response).to have_http_status(:created)

      get "/api/envelopes/#{env_id}", headers: auth_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      body = response.parsed_body
      expect(body["spent"]).to eq("amount_minor" => 300_000, "currency" => "VND")
      expect(body["remaining"]).to eq("amount_minor" => 1_700_000, "currency" => "VND")
    end
  end

  describe "GET /api/envelopes/:id" do
    it "returns 404 (not the row) for another user's envelope" do
      create_envelope(bob, { name: "Bob Secret" })
      bob_id = response.parsed_body["id"]

      get "/api/envelopes/#{bob_id}", headers: auth_headers(alice)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
      expect(response.body).not_to include("Bob Secret")
    end
  end

  describe "PATCH /api/envelopes/:id" do
    it "updates an envelope's name and allocation" do
      create_envelope(alice, { name: "Food", allocation_minor_units: 1_000_000 })
      id = response.parsed_body["id"]

      patch "/api/envelopes/#{id}", params: { name: "Groceries", allocation_minor_units: 1_500_000 }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      body = response.parsed_body
      expect(body["name"]).to eq("Groceries")
      expect(body["allocation"]).to eq("amount_minor" => 1_500_000, "currency" => "VND")
    end

    it "returns 404 when updating another user's envelope" do
      create_envelope(bob, { name: "Bob" })
      bob_id = response.parsed_body["id"]

      patch "/api/envelopes/#{bob_id}", params: { name: "Hacked" }.to_json,
            headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
    end
  end

  describe "DELETE /api/envelopes/:id" do
    it "deletes the caller's envelope" do
      create_envelope(alice, { name: "Food" })
      id = response.parsed_body["id"]

      delete "/api/envelopes/#{id}", headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:no_content)
      expect(Envelope.exists?(id)).to be(false)
    end

    it "returns 404 when deleting another user's envelope" do
      create_envelope(bob, { name: "Bob" })
      bob_id = response.parsed_body["id"]

      delete "/api/envelopes/#{bob_id}", headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:not_found)
      assert_conforms_to_contract(404)
    end
  end

  describe "POST /api/starter_envelopes (seeding, idempotent)" do
    it "seeds the suggested set and designates a single reserve" do
      post "/api/starter_envelopes", params: {}.to_json, headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      envelopes = response.parsed_body["envelopes"]
      expect(envelopes.size).to eq(StarterEnvelopes::SET.size)
      expect(envelopes.count { |e| e["is_reserve"] }).to eq(1)
    end

    it "does not duplicate envelopes that already exist by name (case-insensitive, trimmed)" do
      create_envelope(alice, { name: "  food  " })

      post "/api/starter_envelopes", params: {}.to_json, headers: auth_headers(alice, body: true)
      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)

      names = response.parsed_body["envelopes"].map { |e| e["name"].strip.downcase }
      expect(names.count("food")).to eq(1)
      expect(response.parsed_body["envelopes"].size).to eq(StarterEnvelopes::SET.size)
    end

    it "is idempotent — a second seeding adds nothing" do
      post "/api/starter_envelopes", params: {}.to_json, headers: auth_headers(alice, body: true)
      first = response.parsed_body["envelopes"].size

      post "/api/starter_envelopes", params: {}.to_json, headers: auth_headers(alice, body: true)
      expect(response.parsed_body["envelopes"].size).to eq(first)
    end

    it "does not designate a reserve when one already exists" do
      create_envelope(alice, { name: "My Reserve", is_reserve: true })

      post "/api/starter_envelopes", params: {}.to_json, headers: auth_headers(alice, body: true)

      reserves = response.parsed_body["envelopes"].count { |e| e["is_reserve"] }
      expect(reserves).to eq(1)
    end
  end

  describe "POST /api/allocation_template (save + apply to a month)" do
    it "seeds a month's allocations from the provided template lines" do
      create_envelope(alice, { name: "Food", allocation_minor_units: 0 })
      food = response.parsed_body["id"]
      create_envelope(alice, { name: "Rent", allocation_minor_units: 0 })
      rent = response.parsed_body["id"]

      post "/api/allocation_template",
           params: { month: "2026-06",
                     allocations: [ { envelope_id: food, amount_minor_units: 2_000_000 },
                                    { envelope_id: rent, amount_minor_units: 8_000_000 } ] }.to_json,
           headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      by_name = response.parsed_body["envelopes"].index_by { |e| e["name"] }
      expect(by_name["Food"]["allocation"]).to eq("amount_minor" => 2_000_000, "currency" => "VND")
      expect(by_name["Rent"]["allocation"]).to eq("amount_minor" => 8_000_000, "currency" => "VND")
      # The template default was saved on the envelope too.
      expect(Envelope.find(food).allocation_minor_units).to eq(2_000_000)
      expect(EnvelopeAllocation.where(envelope_id: food).count).to eq(1)
    end

    it "applies existing defaults to a month when no lines are given" do
      create_envelope(alice, { name: "Food", allocation_minor_units: 1_234_000 })
      food = response.parsed_body["id"]

      post "/api/allocation_template", params: { month: "2026-07" }.to_json,
           headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:created)
      snapshot = EnvelopeAllocation.find_by(envelope_id: food, month: Date.new(2026, 7, 1))
      expect(snapshot.allocation_minor_units).to eq(1_234_000)
    end

    it "is idempotent — re-applying a month overwrites the snapshot, not duplicates" do
      create_envelope(alice, { name: "Food" })
      food = response.parsed_body["id"]

      post "/api/allocation_template",
           params: { month: "2026-06", allocations: [ { envelope_id: food, amount_minor_units: 100 } ] }.to_json,
           headers: auth_headers(alice, body: true)
      post "/api/allocation_template",
           params: { month: "2026-06", allocations: [ { envelope_id: food, amount_minor_units: 200 } ] }.to_json,
           headers: auth_headers(alice, body: true)

      expect(EnvelopeAllocation.where(envelope_id: food, month: Date.new(2026, 6, 1)).count).to eq(1)
      expect(EnvelopeAllocation.find_by(envelope_id: food, month: Date.new(2026, 6, 1)).allocation_minor_units).to eq(200)
    end

    it "rejects a line referencing another user's envelope with 422" do
      post "/api/envelopes", params: { name: "Bob" }.to_json, headers: auth_headers(bob, body: true)
      bob_env = response.parsed_body["id"]

      post "/api/allocation_template",
           params: { allocations: [ { envelope_id: bob_env, amount_minor_units: 100 } ] }.to_json,
           headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end

    it "rejects a malformed month with 422" do
      create_envelope(alice, { name: "Food" })

      post "/api/allocation_template", params: { month: "nope" }.to_json,
           headers: auth_headers(alice, body: true)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end
  end
end

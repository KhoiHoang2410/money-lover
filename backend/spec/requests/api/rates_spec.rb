require "rails_helper"

# Rate service API (issue 19). Asserts resolved reads, override set/clear,
# per-User isolation, auth, and OpenAPI conformance (the contract gate bites via
# assert_conforms_to_contract).
RSpec.describe "Api::Rates", type: :request do
  def json_headers(user)
    headers = { "Accept" => "application/json", "Content-Type" => "application/json" }
    headers["Authorization"] = "Bearer #{Auth::TokenService.issue_access_token(user)}" if user
    headers
  end

  let(:alice) { Auth::PasswordProvider.register(username: "alice", password: "secret123") }
  let(:bob)   { Auth::PasswordProvider.register(username: "bob",   password: "secret123") }

  before do
    Rate.create!(key: "fx.USD", value: BigDecimal("25500"), source: "fx",
                 fetched_at: Time.utc(2026, 6, 20, 8), stale: false)
    Rate.create!(key: "gold", value: BigDecimal("6950000"), source: "sjc",
                 fetched_at: Time.utc(2026, 6, 20, 8), stale: true)
  end

  describe "GET /rates" do
    it "returns the resolved rates and conforms to the contract" do
      get "/rates", headers: json_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)

      rates = response.parsed_body.fetch("rates")
      usd = rates.find { |r| r["key"] == "fx.USD" }
      expect(usd["value"]).to eq("25500")
      expect(usd["source"]).to eq("fx")
      expect(usd["overridden"]).to be(false)

      gold = rates.find { |r| r["key"] == "gold" }
      expect(gold["stale"]).to be(true)
    end

    it "reflects the caller's override and isolates it from another user" do
      put "/rates/fx.USD/override", params: { value: "26000" }.to_json,
          headers: json_headers(alice)
      expect(response).to have_http_status(:ok)

      get "/rates", headers: json_headers(alice)
      alice_usd = response.parsed_body.fetch("rates").find { |r| r["key"] == "fx.USD" }
      expect(alice_usd["value"]).to eq("26000")
      expect(alice_usd["overridden"]).to be(true)

      get "/rates", headers: json_headers(bob)
      bob_usd = response.parsed_body.fetch("rates").find { |r| r["key"] == "fx.USD" }
      expect(bob_usd["value"]).to eq("25500")
      expect(bob_usd["overridden"]).to be(false)
    end

    it "rejects an unauthenticated request" do
      get "/rates", headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
      expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
    end
  end

  describe "PUT /rates/:key/override" do
    it "stores the override and returns the resolved rate (conformant)" do
      put "/rates/fx.USD/override", params: { value: "26000" }.to_json,
          headers: json_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["value"]).to eq("26000")
      expect(response.parsed_body["overridden"]).to be(true)
    end

    it "supports an override for a key with no global (stock.<TICKER>)" do
      put "/rates/stock.VNM/override", params: { value: "70000" }.to_json,
          headers: json_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["value"]).to eq("70000")
      expect(response.parsed_body["source"]).to be_nil
    end

    it "rejects an invalid value with a 422 envelope" do
      put "/rates/fx.USD/override", params: { value: "-1" }.to_json,
          headers: json_headers(alice)

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end

    it "rejects an unauthenticated request" do
      put "/rates/fx.USD/override", params: { value: "26000" }.to_json,
          headers: { "Accept" => "application/json", "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /rates/:key/override" do
    it "clears the override and is idempotent" do
      put "/rates/fx.USD/override", params: { value: "26000" }.to_json,
          headers: json_headers(alice)

      delete "/rates/fx.USD/override", headers: json_headers(alice)
      expect(response).to have_http_status(:no_content)

      get "/rates", headers: json_headers(alice)
      usd = response.parsed_body.fetch("rates").find { |r| r["key"] == "fx.USD" }
      expect(usd["value"]).to eq("25500")
      expect(usd["overridden"]).to be(false)

      delete "/rates/fx.USD/override", headers: json_headers(alice)
      expect(response).to have_http_status(:no_content)
    end
  end
end

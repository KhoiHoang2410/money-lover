require "rails_helper"

# The auth token lifecycle (ADR-0014, issue 06): register → login → refresh →
# logout, plus the negative paths the security properties depend on. Every
# response is asserted against the OpenAPI contract (ADR-0017).
RSpec.describe "Auth", type: :request do
  let(:json) { { "Accept" => "application/json", "Content-Type" => "application/json" } }

  def post_json(path, body)
    post path, params: body.to_json, headers: json
  end

  describe "POST /auth/register" do
    it "creates a user and returns a token pair" do
      post_json("/auth/register", { username: "alice", password: "secret123" })

      expect(response).to have_http_status(:created)
      assert_conforms_to_contract(201)
      body = response.parsed_body
      expect(body["token_type"]).to eq("Bearer")
      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to be_present
      expect(Identity.find_by(provider: "password", external_id: "alice")).to be_present
    end

    it "honors a supplied timezone" do
      post_json("/auth/register", { username: "bob", password: "secret123", timezone: "Europe/London" })

      expect(response).to have_http_status(:created)
      expect(Identity.find_by_credentials(provider: "password", external_id: "bob").user.timezone)
        .to eq("Europe/London")
    end

    it "rejects a duplicate username with 422" do
      Auth::PasswordProvider.register(username: "alice", password: "secret123")

      post_json("/auth/register", { username: "alice", password: "another12" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end

    it "rejects a missing password with 422" do
      post_json("/auth/register", { username: "alice" })

      expect(response).to have_http_status(:unprocessable_entity)
      assert_conforms_to_contract(422)
    end
  end

  describe "POST /auth/login" do
    before { Auth::PasswordProvider.register(username: "alice", password: "secret123") }

    it "returns a token pair for valid credentials" do
      post_json("/auth/login", { username: "alice", password: "secret123" })

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["access_token"]).to be_present
    end

    it "rejects invalid credentials with 401" do
      post_json("/auth/login", { username: "alice", password: "wrongpass" })

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
      expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
    end

    it "rejects an unknown username with 401" do
      post_json("/auth/login", { username: "ghost", password: "secret123" })

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /auth/refresh" do
    before { Auth::PasswordProvider.register(username: "alice", password: "secret123") }

    def login
      post_json("/auth/login", { username: "alice", password: "secret123" })
      response.parsed_body
    end

    it "rotates the refresh token and returns a new pair" do
      original = login["refresh_token"]

      post_json("/auth/refresh", { refresh_token: original })

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body["refresh_token"]).not_to eq(original)
    end

    it "rejects reusing a rotated refresh token with 401" do
      original = login["refresh_token"]
      post_json("/auth/refresh", { refresh_token: original })

      post_json("/auth/refresh", { refresh_token: original })

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
    end
  end

  describe "POST /auth/logout" do
    before { Auth::PasswordProvider.register(username: "alice", password: "secret123") }

    it "revokes the refresh token so it can no longer be refreshed" do
      post_json("/auth/login", { username: "alice", password: "secret123" })
      refresh_token = response.parsed_body["refresh_token"]

      post_json("/auth/logout", { refresh_token: refresh_token })
      expect(response).to have_http_status(:no_content)

      post_json("/auth/refresh", { refresh_token: refresh_token })
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "full happy path" do
    it "registers, logs in, refreshes, and logs out" do
      post_json("/auth/register", { username: "alice", password: "secret123" })
      expect(response).to have_http_status(:created)

      post_json("/auth/login", { username: "alice", password: "secret123" })
      expect(response).to have_http_status(:ok)
      refresh_token = response.parsed_body["refresh_token"]

      post_json("/auth/refresh", { refresh_token: refresh_token })
      expect(response).to have_http_status(:ok)
      new_refresh = response.parsed_body["refresh_token"]

      post_json("/auth/logout", { refresh_token: new_refresh })
      expect(response).to have_http_status(:no_content)
    end
  end
end

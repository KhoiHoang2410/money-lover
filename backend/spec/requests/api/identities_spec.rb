require "rails_helper"

# Authorization is the point of this issue: the tenant scoping must make one
# user's rows unreachable to another, returning not-found (never the row).
# Identity is the representative tenant-scoped resource; issues 13–20 reuse the
# same `load_owned!` helper for every domain resource.
RSpec.describe "Api::Identities", type: :request do
  # Authenticate as a real bearer access token (issue 06 replaced the X-User-Id
  # shim with JWT decoding in the Tenancy concern).
  def json_headers(user)
    headers = { "Accept" => "application/json" }
    headers["Authorization"] = "Bearer #{Auth::TokenService.issue_access_token(user)}" if user
    headers
  end

  let(:alice) { Auth::PasswordProvider.register(username: "alice", password: "secret123") }
  let(:bob)   { Auth::PasswordProvider.register(username: "bob",   password: "secret123") }
  let(:alice_identity) { alice.identities.sole }
  let(:bob_identity)   { bob.identities.sole }

  it "lets a user read their own identity" do
    get "/api/identities/#{alice_identity.id}", headers: json_headers(alice)

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["id"]).to eq(alice_identity.id)
    expect(body["provider"]).to eq("password")
    expect(body["external_id"]).to eq("alice")
    expect(body).not_to have_key("password_digest")
  end

  it "returns not-found (not the row) when a user requests another user's identity" do
    get "/api/identities/#{bob_identity.id}", headers: json_headers(alice)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")
    # The cross-tenant row's data must not leak in the response body.
    expect(response.body).not_to include("bob")
  end

  it "rejects an unauthenticated request" do
    get "/api/identities/#{alice_identity.id}", headers: { "Accept" => "application/json" }

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
  end

  it "rejects an expired access token" do
    expired = Auth::TokenService.issue_access_token(
      alice, now: Auth::TokenService::ACCESS_TOKEN_TTL.ago - 1.minute
    )

    get "/api/identities/#{alice_identity.id}",
        headers: { "Accept" => "application/json", "Authorization" => "Bearer #{expired}" }

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
  end
end

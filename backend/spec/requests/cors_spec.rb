require "rails_helper"

# CORS for the browser SPA (ADR-0014, webapp issue 01). The web client makes
# credentialed cross-origin requests (to send/receive the httpOnly refresh
# cookie), which the browser only permits when the server echoes the origin and
# allows credentials. These specs exercise the rack-cors middleware directly via
# a CORS preflight (OPTIONS) — no controller is involved.
RSpec.describe "CORS", type: :request do
  # Matches the default WEB_CORS_ORIGINS in config/initializers/cors.rb.
  let(:web_origin) { "http://localhost:5173" }

  def preflight(path, origin:, method: "POST")
    process :options, path, headers: {
      "HTTP_ORIGIN" => origin,
      "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => method,
      "HTTP_ACCESS_CONTROL_REQUEST_HEADERS" => "Content-Type"
    }
  end

  it "permits the configured web origin with credentials on a preflight" do
    preflight("/auth/login", origin: web_origin)

    # rack-cors short-circuits an allowed preflight with a 2xx and no body.
    expect(response.status).to be_between(200, 204)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq(web_origin)
    expect(response.headers["Access-Control-Allow-Credentials"]).to eq("true")
    expect(response.headers["Access-Control-Allow-Methods"]).to include("POST")
  end

  it "permits the refresh endpoint for the web origin with credentials" do
    preflight("/auth/refresh", origin: web_origin)

    expect(response.headers["Access-Control-Allow-Origin"]).to eq(web_origin)
    expect(response.headers["Access-Control-Allow-Credentials"]).to eq("true")
  end

  it "does not grant CORS access to an unconfigured origin" do
    preflight("/auth/login", origin: "https://evil.example.com")

    expect(response.headers["Access-Control-Allow-Origin"]).to be_blank
  end
end

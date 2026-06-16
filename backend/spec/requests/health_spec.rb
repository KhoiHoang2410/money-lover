require "rails_helper"

RSpec.describe "Health", type: :request do
  it "returns JSON status ok" do
    get "/health", headers: { "Accept" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body).to eq("status" => "ok")
  end

  it "rejects a non-JSON Accept header" do
    get "/health", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:not_acceptable)
    expect(response.parsed_body.dig("error", "code")).to eq("not_acceptable")
  end

  it "rejects a non-JSON request content type" do
    get "/health",
        headers: { "Content-Type" => "text/plain",
                   "Accept" => "application/json" }

    expect(response).to have_http_status(:unsupported_media_type)
    expect(response.parsed_body.dig("error", "code")).to eq("unsupported_media_type")
  end
end

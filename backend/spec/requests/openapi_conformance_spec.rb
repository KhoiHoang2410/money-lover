require "rails_helper"

# Meta-tests for the OpenAPI conformance gate itself (ADR-0017). These prove the
# gate actually bites: a real conformant response passes, and a deliberately
# wrong response shape is rejected. Without the negative case a green suite would
# not prove the contract is being enforced.
RSpec.describe "OpenAPI conformance gate", type: :request do
  it "passes a conformant live response against the contract" do
    get "/health", headers: { "Accept" => "application/json" }

    assert_conforms_to_contract(200)
  end

  it "flags a response whose shape violates the contract" do
    # Force /health to emit a body that breaks the HealthStatus schema:
    # `status` is constrained to the enum ["ok"], and additionalProperties is
    # false, so both the bad value and the stray key are violations.
    allow_any_instance_of(HealthController).to receive(:show) do |controller|
      controller.render json: { status: "degraded", surprise: true }
    end

    get "/health", headers: { "Accept" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect { assert_conforms_to_contract(200) }
      .to raise_error(Committee::InvalidResponse)
  end
end

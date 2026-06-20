# OpenAPI contract conformance gate (ADR-0017).
#
# The hand-maintained contract at docs/api/openapi.yaml is the source of truth
# for the JSON API. Here we wire committee-rails so request specs can assert
# that live responses (and accepted params) conform to it. Any drift between a
# real response and the contract fails the suite.
#
# Usage from a request spec (type: :request):
#
#   get "/health", headers: { "Accept" => "application/json" }
#   assert_conforms_to_contract(200)   # or assert_response_schema_confirm(200)
#
# When you add an endpoint, extend docs/api/openapi.yaml first (see
# backend/README.md § "Extending the OpenAPI contract"), then assert conformance
# in that resource's request spec.
require "committee"
require "committee/rails/test/methods"

# The contract lives at the repo root (docs/api/), one level above Rails.root
# (backend/) in the monorepo (ADR-0016).
OPENAPI_CONTRACT_PATH = Rails.root.join("..", "docs", "api", "openapi.yaml").expand_path.freeze

module OpenapiContract
  include Committee::Rails::Test::Methods

  # Intention-first wrapper around committee's assert_response_schema_confirm:
  # asserts the just-made response conforms to the contract for `status`.
  def assert_conforms_to_contract(status = response.status)
    assert_response_schema_confirm(status)
  end
end

RSpec.configure do |config|
  # committee-rails reads validation options from RSpec.configuration; expose
  # the setting and point it at our contract.
  config.add_setting :committee_options
  config.committee_options = {
    schema_path: OPENAPI_CONTRACT_PATH.to_s,
    # Fail fast if a $ref in the contract cannot be resolved.
    strict_reference_validation: true,
    # Validate every status (including 4xx/5xx error envelopes), not just 2xx.
    validate_success_only: false
  }

  config.include OpenapiContract, type: :request
end

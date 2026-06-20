module Api
  # Starter envelopes seeding (issue 15, CONTEXT.md "Starter envelopes"): a
  # createable resource that populates the caller's Envelope list from the single
  # hard-coded suggested set. Idempotent on existing names (case-insensitive,
  # trimmed) and designates the Reserve only when the caller has none. Returns the
  # resulting Envelope list (conforming to the OpenAPI contract, ADR-0017).
  class StarterEnvelopesController < BaseController
    include EnvelopeRendering

    def create
      StarterEnvelopes.seed!(current_user)
      render json: envelopes_payload, status: :created
    end
  end
end

require "dry/validation"

module Reconciliations
  # dry-validation contract for POST /api/reconciliations (ADR-0017, issue 17).
  # The body submits each money source's re-entered **real balance** as integer
  # minor units (never a float — ADR-0015). Source ownership and the
  # source-currency match are enforced in the controller (they need the
  # caller's records); this contract guards shape and primitive types.
  class CreateContract < Dry::Validation::Contract
    params do
      required(:balances).array(:hash) do
        required(:source_id).filled(:integer)
        required(:amount_minor_units).filled(:integer)
        required(:currency).filled(:string)
        optional(:envelope_id).filled(:integer)
        optional(:note).maybe(:string)
      end
    end

    rule(:balances) do
      key.failure("must include at least one source") if value.respond_to?(:empty?) && value.empty?
    end

    rule(:balances).each do
      next if value[:currency].nil?

      unless Currency::ALL.map(&:to_s).include?(value[:currency])
        key.failure("currency must be one of #{Currency::ALL.join(', ')}")
      end
    end
  end
end

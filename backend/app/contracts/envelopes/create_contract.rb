require "dry/validation"

module Envelopes
  # dry-validation contract for POST /envelopes (ADR-0017: params validated by
  # dry-validation, not the model). A name is required; the Allocation and caps
  # default/optional but must be non-negative; currency must be a known code.
  # The "exactly one Reserve" invariant is cross-row, so it is enforced on the
  # model/DB (a partial unique index), not here.
  class CreateContract < Dry::Validation::Contract
    params do
      required(:name).filled(:string)
      optional(:icon).maybe(:string)
      optional(:is_reserve).filled(:bool)
      optional(:currency).filled(:string)
      optional(:allocation_minor_units).filled(:integer)
      optional(:weekly_cap_minor_units).filled(:integer)
      optional(:monthly_cap_minor_units).filled(:integer)
    end

    rule(:currency) do
      if key? && !Currency::ALL.map(&:to_s).include?(value)
        key.failure("must be one of #{Currency::ALL.join(', ')}")
      end
    end

    rule(:allocation_minor_units) do
      key.failure("must be a non-negative amount") if key? && value.negative?
    end

    rule(:weekly_cap_minor_units) do
      key.failure("must be a non-negative amount") if key? && value.negative?
    end

    rule(:monthly_cap_minor_units) do
      key.failure("must be a non-negative amount") if key? && value.negative?
    end
  end
end

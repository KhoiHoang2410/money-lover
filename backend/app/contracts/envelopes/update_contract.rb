require "dry/validation"

module Envelopes
  # dry-validation contract for PATCH /envelopes/:id. Every field is optional (a
  # partial update); the same non-negativity / enum rules apply to any provided
  # value. The "exactly one Reserve" invariant is enforced on the model/DB.
  class UpdateContract < Dry::Validation::Contract
    params do
      optional(:name).filled(:string)
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

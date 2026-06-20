require "dry/validation"

module Sources
  # dry-validation contract for PATCH /sources/:id. Every field is optional (a
  # partial update); `kind` is immutable and not accepted here. Provided values
  # are type/enum-checked; the controller applies only the fields relevant to the
  # record's existing kind.
  class UpdateContract < Dry::Validation::Contract
    params do
      optional(:name).filled(:string)
      optional(:icon).maybe(:string)
      optional(:logo).maybe(:string)
      optional(:currency).filled(:string)
      optional(:opening_minor_units).filled(:integer)
      optional(:opening_quantity).filled(:string)
      optional(:unit).filled(:string)
      optional(:ticker).maybe(:string)
    end

    rule(:currency) do
      if key? && !Currency::ALL.map(&:to_s).include?(value)
        key.failure("must be one of #{Currency::ALL.join(', ')}")
      end
    end

    rule(:unit) do
      if key? && !HoldingUnit::ALL.map(&:to_s).include?(value)
        key.failure("must be one of #{HoldingUnit::ALL.join(', ')}")
      end
    end

    rule(:opening_quantity) do
      if key? && !Sources.valid_quantity?(value)
        key.failure("must be a non-negative number")
      end
    end
  end
end

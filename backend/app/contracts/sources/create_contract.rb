require "dry/validation"

module Sources
  # dry-validation contract for POST /sources (ADR-0017: params validated by
  # dry-validation, not the model). Encodes the kind-conditional shape:
  #   * account / credit_card — require a currency + opening minor units.
  #   * holding — require an opening quantity + unit; a stock (shares) needs a
  #     ticker, a gold holding (chỉ/lượng) must not carry one (CONTEXT.md).
  class CreateContract < Dry::Validation::Contract
    params do
      required(:kind).filled(:string)
      required(:name).filled(:string)
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

    # kind is always present, so this single rule drives every kind-conditional
    # requirement (a rule keyed on an absent optional field would not run).
    rule(:kind) do
      unless Source::KINDS.include?(value)
        key.failure("must be one of #{Source::KINDS.join(', ')}")
        next
      end

      if value == Source::HOLDING
        key([ :opening_quantity ]).failure("is required for a holding") if values[:opening_quantity].nil?
        key([ :unit ]).failure("is required for a holding") if values[:unit].nil?

        if values[:unit] == "shares"
          key([ :ticker ]).failure("is required for a stock holding") if values[:ticker].to_s.strip.empty?
        elsif %w[chi luong].include?(values[:unit])
          key([ :ticker ]).failure("must be blank for a gold holding") unless values[:ticker].to_s.strip.empty?
        end
      else
        key([ :currency ]).failure("is required for an account or credit card") if values[:currency].nil?
        key([ :opening_minor_units ]).failure("is required for an account or credit card") if values[:opening_minor_units].nil?
      end
    end
  end

  module_function

  # An opening quantity is valid when it parses as an exact, non-negative number.
  def valid_quantity?(value)
    Quantity.new(value, unit: :chi).value >= 0
  rescue StandardError
    false
  end
end

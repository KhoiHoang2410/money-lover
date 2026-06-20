require "dry/validation"

module Transactions
  # dry-validation contract for POST /transactions (ADR-0017: params validated by
  # dry-validation, not the model). Required fields differ by kind (CONTEXT.md):
  #   * expense / income / adjustment — a source + amount.
  #   * transfer — a source + destination + amount; cross-currency adds a
  #     destination amount and a manual Rate (the Fee is computed, never entered).
  #   * invest — an Account source + Holding destination + amount, a trade
  #     quantity and a buy/sell direction; VND-only.
  class CreateContract < Dry::Validation::Contract
    params do
      required(:kind).filled(:string)
      required(:source_id).filled(:integer)
      optional(:destination_id).filled(:integer)
      optional(:amount_minor_units).filled(:integer)
      optional(:currency).filled(:string)
      optional(:destination_amount_minor_units).filled(:integer)
      optional(:destination_currency).filled(:string)
      optional(:manual_rate).filled(:string)
      optional(:trade_quantity).filled(:string)
      optional(:trade_direction).filled(:string)
      optional(:envelope_id).filled(:integer)
      optional(:goal_id).filled(:integer)
      optional(:note).maybe(:string)
      optional(:occurred_on).filled(:date)
      optional(:backfill).filled(:bool)
    end

    rule(:currency) do
      if key? && !Currency::ALL.map(&:to_s).include?(value)
        key.failure("must be one of #{Currency::ALL.join(', ')}")
      end
    end

    rule(:destination_currency) do
      if key? && !Currency::ALL.map(&:to_s).include?(value)
        key.failure("must be one of #{Currency::ALL.join(', ')}")
      end
    end

    rule(:trade_direction) do
      if key? && !Transaction::DIRECTIONS.include?(value)
        key.failure("must be one of #{Transaction::DIRECTIONS.join(', ')}")
      end
    end

    rule(:trade_quantity) do
      if key? && !Transactions.positive_quantity?(value)
        key.failure("must be a positive number")
      end
    end

    rule(:manual_rate) do
      if key? && !Transactions.positive_decimal?(value)
        key.failure("must be a positive number")
      end
    end

    # kind is always present, so this single rule drives every kind-conditional
    # requirement (a rule keyed on an absent optional field would not run).
    rule(:kind) do
      unless Transaction::KINDS.include?(value)
        key.failure("must be one of #{Transaction::KINDS.join(', ')}")
        next
      end

      key([ :amount_minor_units ]).failure("is required") if values[:amount_minor_units].nil?
      key([ :currency ]).failure("is required") if values[:currency].nil?

      case value
      when Transaction::TRANSFER
        key([ :destination_id ]).failure("is required for a transfer") if values[:destination_id].nil?

        cross_currency = values[:destination_currency].present? &&
                         values[:destination_currency] != values[:currency]
        if cross_currency
          if values[:destination_amount_minor_units].nil?
            key([ :destination_amount_minor_units ]).failure("is required for a cross-currency transfer")
          end
          key([ :manual_rate ]).failure("is required for a cross-currency transfer") if values[:manual_rate].nil?
        end
      when Transaction::INVEST
        key([ :destination_id ]).failure("is required for an invest") if values[:destination_id].nil?
        key([ :trade_quantity ]).failure("is required for an invest") if values[:trade_quantity].nil?
        key([ :trade_direction ]).failure("is required for an invest") if values[:trade_direction].nil?
        if values[:currency].present? && values[:currency] != Source::BASE_CURRENCY
          key([ :currency ]).failure("must be VND for an invest")
        end
      end
    end
  end

  module_function

  # A trade quantity is valid when it parses as an exact, strictly-positive number.
  def positive_quantity?(value)
    Quantity.exact(value).positive?
  rescue StandardError
    false
  end

  # A manual rate is valid when it parses as an exact, strictly-positive number.
  def positive_decimal?(value)
    Money.exact(value).positive?
  rescue StandardError
    false
  end
end

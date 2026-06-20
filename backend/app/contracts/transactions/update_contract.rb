require "dry/validation"

module Transactions
  # dry-validation contract for PATCH /transactions/:id. A partial update of the
  # mutable fields; `kind`, `source_id` and `destination_id` are immutable (they
  # would change which sources the row touches, so re-create instead). Amounts and
  # the trade quantity stay re-validated so editing cannot smuggle in a bad value;
  # the controller re-derives the Fee and re-checks the oversell guard.
  class UpdateContract < Dry::Validation::Contract
    params do
      optional(:amount_minor_units).filled(:integer)
      optional(:destination_amount_minor_units).filled(:integer)
      optional(:manual_rate).filled(:string)
      optional(:trade_quantity).filled(:string)
      optional(:envelope_id).filled(:integer)
      optional(:goal_id).filled(:integer)
      optional(:note).maybe(:string)
      optional(:occurred_on).filled(:date)
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
  end
end

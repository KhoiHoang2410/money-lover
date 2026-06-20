require "dry/validation"

module Contributions
  # dry-validation contract for POST /goals/:id/contributions (ADR-0017). A
  # Contribution (CONTEXT.md) moves money from a VND Account into a Goal, recorded
  # as a Transfer. Here we validate only the param shape: a source, a positive
  # amount, an optional date/note. VND-only — a currency, if given, must be VND;
  # the controller additionally enforces that the source is a VND Account.
  class CreateContract < Dry::Validation::Contract
    params do
      required(:source_id).filled(:integer)
      required(:amount_minor_units).filled(:integer)
      optional(:currency).filled(:string)
      optional(:occurred_on).filled(:date)
      optional(:note).maybe(:string)
    end

    rule(:amount_minor_units) do
      key.failure("must be a positive amount") if value && value <= 0
    end

    rule(:currency) do
      key.failure("must be VND") if key? && value != Source::BASE_CURRENCY
    end
  end
end

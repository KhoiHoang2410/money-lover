require "dry/validation"

module Reports
  # dry-validation contract for the date-range report endpoints (issue 18):
  # spending trends and balance / net-worth history. `from` and `to` are ISO-8601
  # dates (coerced from the query string); the range must be well-formed
  # (`from` <= `to`) so a client chart asks for a sane window.
  class RangeContract < Dry::Validation::Contract
    params do
      required(:from).filled(:date)
      required(:to).filled(:date)
    end

    rule(:to) do
      key.failure("must be on or after `from`") if values[:from] && value && value < values[:from]
    end
  end
end

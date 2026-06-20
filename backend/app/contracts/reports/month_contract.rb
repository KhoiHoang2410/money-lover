require "dry/validation"

module Reports
  # dry-validation contract for the per-month report endpoints (issue 18): the
  # envelope/bucket distribution. `month` is an optional `YYYY-MM` string; when
  # omitted the controller defaults to the caller's current month (resolved in
  # their timezone). A malformed month is rejected with a structured 422.
  class MonthContract < Dry::Validation::Contract
    MONTH_FORMAT = /\A\d{4}-(0[1-9]|1[0-2])\z/

    params do
      optional(:month).filled(:string)
    end

    rule(:month) do
      key.failure("must be a YYYY-MM month") if key? && !MONTH_FORMAT.match?(value)
    end
  end
end

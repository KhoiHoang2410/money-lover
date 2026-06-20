require "dry/validation"

module Goals
  # dry-validation contract for POST /goals (ADR-0017: params validated by
  # dry-validation, not the model). A Goal needs a name, a positive target, and a
  # Schedule of month → planned amount; the funding window (start/end month) is
  # optional. VND-only for now (CONTEXT.md "Goal"), so a currency, if given, must
  # be VND. Every money amount is integer minor units (never a float — ADR-0015).
  class CreateContract < Dry::Validation::Contract
    params do
      required(:name).filled(:string)
      optional(:icon).maybe(:string)
      optional(:currency).filled(:string)
      required(:target_minor_units).filled(:integer)

      optional(:start_month).hash do
        required(:year).filled(:integer)
        required(:month).filled(:integer)
      end
      optional(:end_month).hash do
        required(:year).filled(:integer)
        required(:month).filled(:integer)
      end

      required(:schedule).array(:hash) do
        required(:year).filled(:integer)
        required(:month).filled(:integer)
        required(:amount_minor_units).filled(:integer)
      end
    end

    rule(:currency) do
      key.failure("must be VND") if key? && value != Source::BASE_CURRENCY
    end

    rule(:target_minor_units) do
      key.failure("must be a positive amount") if value && value <= 0
    end

    rule(:start_month) do
      if key? && value && !(1..12).cover?(value[:month])
        key([ :start_month, :month ]).failure("must be between 1 and 12")
      end
    end

    rule(:end_month) do
      if key? && value && !(1..12).cover?(value[:month])
        key([ :end_month, :month ]).failure("must be between 1 and 12")
      end
    end

    rule(:schedule) do
      Array(value).each_with_index do |line, index|
        if line[:month] && !(1..12).cover?(line[:month])
          key([ :schedule, index, :month ]).failure("must be between 1 and 12")
        end
        if line[:amount_minor_units] && line[:amount_minor_units] <= 0
          key([ :schedule, index, :amount_minor_units ]).failure("must be a positive amount")
        end
      end
    end
  end
end

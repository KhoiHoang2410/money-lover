require "dry/validation"

module Goals
  # dry-validation contract for PATCH /goals/:id. A partial update of the mutable
  # fields; `currency` is immutable (it would change the meaning of every stored
  # amount, so re-create instead). Amounts stay re-validated so an edit cannot
  # smuggle in a non-positive target or schedule line.
  class UpdateContract < Dry::Validation::Contract
    params do
      optional(:name).filled(:string)
      optional(:icon).maybe(:string)
      optional(:target_minor_units).filled(:integer)

      optional(:start_month).hash do
        required(:year).filled(:integer)
        required(:month).filled(:integer)
      end
      optional(:end_month).hash do
        required(:year).filled(:integer)
        required(:month).filled(:integer)
      end

      optional(:schedule).array(:hash) do
        required(:year).filled(:integer)
        required(:month).filled(:integer)
        required(:amount_minor_units).filled(:integer)
      end
    end

    rule(:target_minor_units) do
      key.failure("must be a positive amount") if key? && value && value <= 0
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

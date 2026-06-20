require "dry/validation"

module AllocationTemplate
  # dry-validation contract for POST /allocation_template — save the template and
  # apply it to a month (CONTEXT.md "Allocation template"). `month` is optional
  # (defaults to the caller's current month); `allocations` is optional (absent →
  # seed the month from each Envelope's existing default). Each line targets one
  # Envelope with a non-negative amount; ownership is checked in the controller.
  class ApplyContract < Dry::Validation::Contract
    params do
      optional(:month).filled(:string)
      optional(:allocations).array(:hash) do
        required(:envelope_id).filled(:integer)
        required(:amount_minor_units).filled(:integer)
      end
    end

    rule(:allocations).each do
      if value && value[:amount_minor_units].negative?
        key([ :amount_minor_units ]).failure("must be a non-negative amount")
      end
    end
  end
end

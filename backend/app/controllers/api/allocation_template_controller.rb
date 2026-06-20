module Api
  # Allocation template apply (issue 15, CONTEXT.md "Allocation template"): a
  # createable resource that saves the template (each Envelope's default
  # Allocation) and seeds a month's per-month Allocation snapshots from it. With
  # no `allocations` it seeds the month from the existing defaults; with a
  # `month` it targets that month, else the caller's current month. Every write is
  # tenant-scoped (a cross-tenant envelope_id → 422) and atomic. Returns the
  # Envelope list for the applied month (OpenAPI-conformant, ADR-0017).
  class AllocationTemplateController < BaseController
    include EnvelopeRendering

    def create
      attrs = validate!(AllocationTemplate::ApplyContract)
      month = parse_month!(attrs[:month])

      ActiveRecord::Base.transaction do
        if attrs[:allocations].present?
          attrs[:allocations].each do |line|
            envelope = owned_envelope!(line[:envelope_id])
            envelope.update!(allocation_minor_units: line[:amount_minor_units])
            upsert_allocation!(envelope, month, line[:amount_minor_units])
          end
        else
          tenant_scope(:envelopes).find_each do |envelope|
            upsert_allocation!(envelope, month, envelope.allocation_minor_units)
          end
        end
      end

      render json: envelopes_payload(month: month), status: :created
    end

    private

    def validate!(contract_class)
      result = contract_class.new.call(contract_params)
      return result.to_h if result.success?

      raise ApiError::Validation.new("Allocation template is invalid.", details: result.errors.to_h)
    end

    def contract_params
      params.permit(:month, allocations: [ :envelope_id, :amount_minor_units ]).to_h
    end

    # Loads one of the caller's envelopes by id, raising a 422 (not a 404) for an
    # absent / cross-tenant reference in the body.
    def owned_envelope!(id)
      envelope = current_user.envelopes.find_by(id: id)
      return envelope if envelope

      raise ApiError::Validation.new("Allocation template is invalid.",
                                     details: { envelope_id: [ "must reference one of your envelopes" ] })
    end

    # Create-or-replace the (envelope, month) Allocation snapshot — apply is
    # idempotent, so re-applying a month overwrites rather than duplicates.
    def upsert_allocation!(envelope, month, amount)
      record = current_user.envelope_allocations.find_or_initialize_by(envelope_id: envelope.id, month: month)
      record.allocation_minor_units = amount
      record.currency = envelope.currency
      record.save!
    end

    # Accepts "YYYY-MM" or a full ISO date, normalizing to the first of the
    # month; a blank value defaults to the caller's current month.
    def parse_month!(raw)
      return current_month if raw.blank?

      str = raw.to_s.strip
      str = "#{str}-01" if str.match?(/\A\d{4}-\d{2}\z/)
      Date.parse(str).beginning_of_month
    rescue ArgumentError, Date::Error
      raise ApiError::Validation.new("Allocation template is invalid.",
                                     details: { month: [ "must be a YYYY-MM or ISO date" ] })
    end
  end
end

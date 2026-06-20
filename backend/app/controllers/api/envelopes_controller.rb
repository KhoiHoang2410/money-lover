module Api
  # CRUD for the current user's Envelopes (issue 15). Every row is loaded through
  # `current_user.envelopes` (Tenancy), so another user's envelope is unreachable
  # — a cross-tenant id yields 404, never the row. Each read returns the month's
  # spent/remaining computed by BudgetEngine (issue 10). Params are validated by
  # dry-validation contracts; responses conform to the OpenAPI contract (ADR-0017).
  # The "exactly one Reserve" invariant is enforced by the model + a partial
  # unique index (a clash → 422).
  class EnvelopesController < BaseController
    include EnvelopeRendering

    def index
      render json: envelopes_payload
    end

    def show
      envelope = load_owned!(:envelopes, params[:id])
      render_envelope(envelope)
    end

    def create
      attrs = validate!(Envelopes::CreateContract)
      envelope = current_user.envelopes.new
      assign_create(envelope, attrs)
      envelope.save!
      render_envelope(envelope, status: :created)
    end

    def update
      envelope = load_owned!(:envelopes, params[:id])
      attrs = validate!(Envelopes::UpdateContract)
      assign_update(envelope, attrs)
      envelope.save!
      render_envelope(envelope)
    end

    def destroy
      envelope = load_owned!(:envelopes, params[:id])
      envelope.destroy!
      head :no_content
    end

    private

    # Runs a dry-validation contract over the permitted params, raising a
    # structured 422 (ApiError::Validation → render_validation) on failure.
    def validate!(contract_class)
      result = contract_class.new.call(contract_params)
      return result.to_h if result.success?

      raise ApiError::Validation.new("Envelope params are invalid.", details: result.errors.to_h)
    end

    def contract_params
      params.permit(
        :name, :icon, :is_reserve, :currency,
        :allocation_minor_units, :weekly_cap_minor_units, :monthly_cap_minor_units
      ).to_h
    end

    def assign_create(envelope, attrs)
      envelope.name = attrs[:name]
      envelope.icon = attrs[:icon]
      envelope.is_reserve = attrs.fetch(:is_reserve, false)
      envelope.currency = attrs[:currency] || Envelope::BASE_CURRENCY
      envelope.allocation_minor_units = attrs.fetch(:allocation_minor_units, 0)
      envelope.weekly_cap_minor_units = attrs[:weekly_cap_minor_units]
      envelope.monthly_cap_minor_units = attrs[:monthly_cap_minor_units]
    end

    def assign_update(envelope, attrs)
      envelope.name = attrs[:name] if attrs.key?(:name)
      envelope.icon = attrs[:icon] if attrs.key?(:icon)
      envelope.is_reserve = attrs[:is_reserve] if attrs.key?(:is_reserve)
      envelope.currency = attrs[:currency] if attrs.key?(:currency)
      envelope.allocation_minor_units = attrs[:allocation_minor_units] if attrs.key?(:allocation_minor_units)
      envelope.weekly_cap_minor_units = attrs[:weekly_cap_minor_units] if attrs.key?(:weekly_cap_minor_units)
      envelope.monthly_cap_minor_units = attrs[:monthly_cap_minor_units] if attrs.key?(:monthly_cap_minor_units)
    end
  end
end

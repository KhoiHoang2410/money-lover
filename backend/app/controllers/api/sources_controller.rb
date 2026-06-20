module Api
  # CRUD for the current user's money sources (issue 13). Every row is loaded
  # through `current_user.sources` (Tenancy), so another user's source is
  # unreachable — a cross-tenant id yields 404, never the row. Params are
  # validated by dry-validation contracts; responses go through SourceRepresenter
  # and conform to the OpenAPI contract (ADR-0017).
  class SourcesController < BaseController
    def index
      transactions = tenant_scope(:transactions).to_a
      presenters = tenant_scope(:sources).order(:id).map do |source|
        SourcePresenter.new(source, transactions: transactions)
      end
      render json: { sources: presenters.map { |p| SourceRepresenter.new(p).to_hash } }
    end

    def show
      source = load_owned!(:sources, params[:id])
      render json: render_source(source)
    end

    def create
      attrs = validate!(Sources::CreateContract)
      source = current_user.sources.new
      assign_create(source, attrs)
      source.save!
      render json: render_source(source), status: :created
    end

    def update
      source = load_owned!(:sources, params[:id])
      attrs = validate!(Sources::UpdateContract)
      assign_update(source, attrs)
      source.save!
      render json: render_source(source)
    end

    def destroy
      source = load_owned!(:sources, params[:id])
      guard_deletable!(source)
      source.destroy!
      head :no_content
    end

    private

    def render_source(source)
      presenter = SourcePresenter.new(source, transactions: tenant_scope(:transactions).to_a)
      SourceRepresenter.new(presenter).to_json
    end

    # Runs a dry-validation contract over the permitted params, raising a
    # structured 422 (ApiError::Validation → render_validation) on failure.
    def validate!(contract_class)
      result = contract_class.new.call(contract_params)
      return result.to_h if result.success?

      raise ApiError::Validation.new("Source params are invalid.", details: result.errors.to_h)
    end

    def contract_params
      params.permit(
        :kind, :name, :icon, :logo, :currency,
        :opening_minor_units, :opening_quantity, :unit, :ticker
      ).to_h
    end

    def assign_create(source, attrs)
      source.kind = attrs[:kind]
      source.name = attrs[:name]
      source.icon = attrs[:icon]
      source.logo = attrs[:logo]

      if attrs[:kind] == Source::HOLDING
        source.currency = attrs[:currency] || Source::BASE_CURRENCY
        source.opening_quantity = attrs[:opening_quantity]
        source.holding_unit = attrs[:unit]
        source.ticker = attrs[:ticker].presence
      else
        source.currency = attrs[:currency]
        source.opening_minor_units = attrs[:opening_minor_units]
      end
    end

    def assign_update(source, attrs)
      source.name = attrs[:name] if attrs.key?(:name)
      source.icon = attrs[:icon] if attrs.key?(:icon)
      source.logo = attrs[:logo] if attrs.key?(:logo)

      if source.account_like?
        source.currency = attrs[:currency] if attrs.key?(:currency)
        source.opening_minor_units = attrs[:opening_minor_units] if attrs.key?(:opening_minor_units)
      else
        source.opening_quantity = attrs[:opening_quantity] if attrs.key?(:opening_quantity)
        source.holding_unit = attrs[:unit] if attrs.key?(:unit)
        source.ticker = attrs[:ticker].presence if attrs.key?(:ticker)
      end
    end

    # Delete integrity (issue 13): block deletion of a source still referenced by
    # transactions with a 409, rather than orphaning ledger rows. Transactions
    # arrive in issue 14; `referenced_by_transactions?` returns false until then,
    # so deletes succeed today and the guard is ready when the ledger lands.
    def guard_deletable!(source)
      return unless source.referenced_by_transactions?

      raise ApiError::Conflict.new("This source has transactions and cannot be deleted.")
    end
  end
end

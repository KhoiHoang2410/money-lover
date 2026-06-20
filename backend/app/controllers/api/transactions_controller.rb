module Api
  # CRUD for the current user's transactions (issue 14). Every row is loaded and
  # written through `current_user.transactions` / `current_user.sources`
  # (Tenancy), so another user's row — or a reference to another user's source —
  # is unreachable: a cross-tenant id yields 404/422, never the data.
  #
  # Balances are computed on read by BalanceEngine (a row is the single source of
  # its ledger deltas), so create/update/delete need no balance bookkeeping. The
  # two write paths that DO touch more than one row are wrapped in a DB
  # transaction so they commit atomically (ADR-0012):
  #   * Backfill — insert the row AND restate each touched source's opening
  #     balance so the current balance is unchanged.
  #   * Invest oversell — reject a Sell that would drive a Holding's quantity
  #     negative (HoldingQuantity) before any row is written.
  class TransactionsController < BaseController
    def index
      scope = tenant_scope(:transactions).order(occurred_on: :desc, id: :desc)
      scope = apply_filters(scope)
      render json: { transactions: scope.map { |txn| represent(txn).to_hash } }
    end

    def show
      txn = load_owned!(:transactions, params[:id])
      render json: represent(txn).to_json
    end

    def create
      attrs = validate!(Transactions::CreateContract)
      txn = current_user.transactions.new
      assign_create(txn, attrs)

      ActiveRecord::Base.transaction do
        guard_oversell!(txn)
        compute_fee!(txn)
        txn.save!
        restate_opening_balances!(txn) if attrs[:backfill]
      end

      render json: represent(txn).to_json, status: :created
    end

    def update
      txn = load_owned!(:transactions, params[:id])
      attrs = validate!(Transactions::UpdateContract)
      assign_update(txn, attrs)

      ActiveRecord::Base.transaction do
        guard_oversell!(txn)
        compute_fee!(txn)
        txn.save!
      end

      render json: represent(txn).to_json
    end

    def destroy
      txn = load_owned!(:transactions, params[:id])
      txn.destroy!
      head :no_content
    end

    private

    def represent(txn)
      TransactionRepresenter.new(TransactionPresenter.new(txn))
    end

    # Filters (issue 14): date range (from/to on occurred_on), source (matches a
    # source OR destination leg — a transfer touches both), envelope, and kind.
    def apply_filters(scope)
      scope = scope.where(kind: params[:kind]) if params[:kind].present?
      scope = scope.where(envelope_id: params[:envelope_id]) if params[:envelope_id].present?
      scope = scope.where("occurred_on >= ?", params[:from]) if params[:from].present?
      scope = scope.where("occurred_on <= ?", params[:to]) if params[:to].present?
      if params[:source_id].present?
        id = params[:source_id]
        scope = scope.where("source_id = :id OR destination_id = :id", id: id)
      end
      scope
    end

    # Runs a dry-validation contract over the permitted params, raising a
    # structured 422 (ApiError::Validation → render_validation) on failure.
    def validate!(contract_class)
      result = contract_class.new.call(contract_params)
      return result.to_h if result.success?

      raise ApiError::Validation.new("Transaction params are invalid.", details: result.errors.to_h)
    end

    def contract_params
      params.permit(
        :kind, :source_id, :destination_id, :amount_minor_units, :currency,
        :destination_amount_minor_units, :destination_currency, :manual_rate,
        :trade_quantity, :trade_direction, :envelope_id, :goal_id, :note,
        :occurred_on, :backfill
      ).to_h
    end

    def assign_create(txn, attrs)
      txn.kind = attrs[:kind]
      txn.source = owned_source!(attrs[:source_id], :source_id)
      txn.destination = attrs[:destination_id] && owned_source!(attrs[:destination_id], :destination_id)
      txn.amount_minor_units = attrs[:amount_minor_units]
      txn.currency = attrs[:currency]
      txn.destination_amount_minor_units = attrs[:destination_amount_minor_units]
      txn.destination_currency = attrs[:destination_currency]
      txn.manual_rate = attrs[:manual_rate]
      txn.trade_quantity = attrs[:trade_quantity]
      txn.trade_direction = attrs[:trade_direction]
      txn.envelope_id = attrs[:envelope_id]
      txn.goal_id = attrs[:goal_id]
      txn.note = attrs[:note]
      txn.occurred_on = attrs[:occurred_on] || Date.current
      txn.backfill = attrs.fetch(:backfill, false)

      validate_references!(txn)
    end

    def assign_update(txn, attrs)
      txn.amount_minor_units = attrs[:amount_minor_units] if attrs.key?(:amount_minor_units)
      txn.destination_amount_minor_units = attrs[:destination_amount_minor_units] if attrs.key?(:destination_amount_minor_units)
      txn.manual_rate = attrs[:manual_rate] if attrs.key?(:manual_rate)
      txn.trade_quantity = attrs[:trade_quantity] if attrs.key?(:trade_quantity)
      txn.envelope_id = attrs[:envelope_id] if attrs.key?(:envelope_id)
      txn.goal_id = attrs[:goal_id] if attrs.key?(:goal_id)
      txn.note = attrs[:note] if attrs.key?(:note)
      txn.occurred_on = attrs[:occurred_on] if attrs.key?(:occurred_on)
    end

    # Loads one of the caller's sources by id, raising a 422 (not a 404) for an
    # absent / cross-tenant reference in the body.
    def owned_source!(id, field)
      source = current_user.sources.find_by(id: id)
      return source if source

      raise ApiError::Validation.new("Transaction params are invalid.",
                                     details: { field => [ "must reference one of your sources" ] })
    end

    # Cross-source kind constraints (CONTEXT.md): an Invest moves money between a
    # VND Account (source) and a Holding (destination).
    def validate_references!(txn)
      return unless txn.kind == Transaction::INVEST

      errors = {}
      errors[:source_id] = [ "must be an account for an invest" ] unless txn.source&.account_like?
      errors[:destination_id] = [ "must be a holding for an invest" ] unless txn.destination&.holding?
      return if errors.empty?

      raise ApiError::Validation.new("Transaction params are invalid.", details: errors)
    end

    # Cross-currency Transfer Fee = (amount_out × rate) − amount_in, in the
    # destination currency (TransferFxMath). Cleared for a same-currency move.
    def compute_fee!(txn)
      unless txn.cross_currency?
        txn.fee_minor_units = nil
        return
      end

      fee = TransferFxMath.fee(amount_out: txn.amount, amount_in: txn.destination_amount, rate: txn.manual_rate)
      txn.fee_minor_units = fee.minor_units
    end

    # Reject a Sell that would drive the Holding's quantity below zero
    # (HoldingQuantity), before any row is written. The whole create/update is
    # wrapped in a DB transaction, so raising here leaves no partial state.
    def guard_oversell!(txn)
      return unless txn.kind == Transaction::INVEST && txn.trade_direction == Transaction::SELL

      holding = txn.destination
      prior = current_user.transactions
                          .where(kind: Transaction::INVEST, destination_id: holding.id)
                          .where.not(id: txn.id)
                          .filter_map(&:to_invest)
      live = HoldingQuantity.live_quantity(
        opening: holding.opening_quantity_value,
        holding_id: holding.id,
        transactions: prior
      )
      return if HoldingQuantity.sell_allowed?(live_quantity: live, sell_quantity: txn.trade_quantity)

      raise ApiError::Validation.new(
        "Cannot sell more than the holding's available quantity.",
        details: { trade_quantity: [ "exceeds the holding's available quantity" ] }
      )
    end

    # Backfill (ADR-0012): restate each money source the row touches so its
    # current balance is unchanged — opening' = opening − (this row's delta on it).
    # The money already moved before tracking began, so only the opening shifts.
    def restate_opening_balances!(txn)
      [ txn.source, txn.destination ].compact.each do |src|
        next unless src.account_like?

        delta = BalanceEngine.delta_for(engine_source(src), txn.to_balance_txn)
        next if delta.nil?

        src.update!(opening_minor_units: (src.opening_minor_units || 0) - delta.minor_units)
      end
    end

    def engine_source(src)
      BalanceEngine::Source.build(
        id: src.id,
        kind: src.kind,
        currency: src.currency,
        opening_balance: src.opening_balance
      )
    end
  end
end

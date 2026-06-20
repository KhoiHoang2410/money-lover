module Api
  # Reconcile as a createable, auditable action (issue 17, ADR-0017,
  # CONTEXT.md "Reconcile"/"Adjustment"). The caller re-enters each money
  # source's **real balance**; the server compares it to the source's
  # **Current balance** (computed by BalanceEngine, issue 07) via ReconcileService
  # (issue 12) and writes one signed Adjustment transaction per source that
  # drifted — never re-deriving the money math here.
  #
  # The whole write is wrapped in one ActiveRecord::Base.transaction, so it is
  # all-or-nothing (ADR-0012): a failure part-way writes no adjustments. Every
  # row is loaded through `current_user.sources` (Tenancy), so a cross-tenant
  # source id is unreachable — it yields 422, never another user's data.
  class ReconciliationsController < BaseController
    def create
      attrs = validate!(Reconciliations::CreateContract)
      entries = build_entries(attrs[:balances])

      adjustments = []
      unchanged = []
      ledger = tenant_scope(:transactions).map(&:to_balance_txn)

      entries.each do |entry|
        adj = ReconcileService.adjustment(
          source: engine_source(entry[:source]),
          transactions: ledger,
          real_balance: entry[:real_balance],
          envelope_id: entry[:envelope_id],
          note: entry[:note]
        )
        if adj.nil?
          unchanged << entry[:source].id
        else
          adjustments << [ entry[:source], adj ]
        end
      end

      created = ActiveRecord::Base.transaction do
        adjustments.map { |source, adj| write_adjustment!(source, adj) }
      end

      render json: represent(created, unchanged).to_json, status: :created
    end

    private

    def represent(adjustments, unchanged_source_ids)
      ReconciliationRepresenter.new(
        ReconciliationPresenter.new(adjustments: adjustments, unchanged_source_ids: unchanged_source_ids)
      )
    end

    # Resolves each submitted balance to the caller's own money source plus the
    # re-entered balance as a `Money`. Rejects an absent/cross-tenant source, a
    # Holding (no money balance to reconcile), or a currency that does not match
    # the source — all as a structured 422, before any row is written, so the
    # pure ReconcileService never has to raise on a mismatch.
    def build_entries(balances)
      balances.map do |balance|
        source = owned_source!(balance[:source_id])
        guard_money_source!(source)
        guard_currency!(source, balance[:currency])

        {
          source: source,
          real_balance: MoneyMapping.load(minor_units: balance[:amount_minor_units], currency: balance[:currency]),
          envelope_id: balance[:envelope_id],
          note: balance[:note]
        }
      end
    end

    # Persists one Adjustment as an `adjustment` Transaction (issue 14 semantics):
    # a signed delta applied directly to the source, so its Current balance lands
    # exactly on the re-entered reality on the next read (BalanceEngine).
    def write_adjustment!(source, adjustment)
      txn = current_user.transactions.new(
        kind: Transaction::ADJUSTMENT,
        source: source,
        amount_minor_units: adjustment.amount.minor_units,
        currency: adjustment.amount.currency.to_s,
        envelope_id: adjustment.envelope_id,
        note: adjustment.note,
        occurred_on: Date.current,
        backfill: false
      )
      txn.save!
      txn
    end

    def owned_source!(id)
      source = current_user.sources.find_by(id: id)
      return source if source

      raise ApiError::Validation.new("Reconcile params are invalid.",
                                     details: { source_id: [ "must reference one of your sources" ] })
    end

    def guard_money_source!(source)
      return if source.account_like?

      raise ApiError::Validation.new("Reconcile params are invalid.",
                                     details: { source_id: [ "must reference an account or credit card" ] })
    end

    def guard_currency!(source, currency)
      return if currency == source.currency

      raise ApiError::Validation.new("Reconcile params are invalid.",
                                     details: { currency: [ "must match the source currency (#{source.currency})" ] })
    end

    # Runs a dry-validation contract over the permitted params, raising a
    # structured 422 (ApiError::Validation → render_validation) on failure.
    def validate!(contract_class)
      result = contract_class.new.call(contract_params)
      return result.to_h if result.success?

      raise ApiError::Validation.new("Reconcile params are invalid.", details: result.errors.to_h)
    end

    def contract_params
      params.permit(balances: [ :source_id, :amount_minor_units, :currency, :envelope_id, :note ]).to_h
    end

    def engine_source(source)
      BalanceEngine::Source.build(
        id: source.id,
        kind: source.kind,
        currency: source.currency,
        opening_balance: source.opening_balance
      )
    end
  end
end

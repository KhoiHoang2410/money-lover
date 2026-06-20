module Api
  # Signal surface (issue 20): the deterministic spending/goal Signals computed
  # for the current User over their own ledger, Envelopes and Goals — envelope
  # pace, projected/actual overspend, a Goal behind plan, a drained Reserve, and
  # an unusually large Expense (CONTEXT.md "Signal").
  #
  # Tenant-scoped via BaseController: every collection is loaded through
  # `current_user`, so a Signal can only ever reflect the caller's own data —
  # another User's Envelopes/Goals/ledger are structurally unreachable (ADR-0014).
  # The math is pure SignalEngine (ADR-0006); the deterministic text is returned
  # directly (no model/LLM — ADR-0004 paused).
  class SignalsController < BaseController
    # GET /signals — the caller's Signals, strongest first.
    def index
      presenter = SignalsPresenter.new(
        envelopes: tenant_scope(:envelopes).includes(:allocations).order(:id).to_a,
        transactions: tenant_scope(:transactions).to_a,
        goals: tenant_scope(:goals).order(:id).to_a,
        as_of: as_of
      )
      render json: { signals: presenter.signals.map { |signal| SignalRepresenter.new(signal).to_hash } }
    end

    private

    # "Today" in the User's timezone (CONTEXT.md): the timezone defines month
    # boundaries and "today" for the Signal pace/Schedule rules.
    def as_of
      zone = ActiveSupport::TimeZone[current_user.timezone] || ActiveSupport::TimeZone["UTC"]
      zone.today
    end
  end
end

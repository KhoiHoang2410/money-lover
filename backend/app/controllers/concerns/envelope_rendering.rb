# Shared read path for the Envelopes surface (issue 15): resolves the caller's
# current month in their timezone, loads that month's Expenses once, and renders
# Envelopes through EnvelopePresenter / EnvelopeRepresenter with spent/remaining.
# Mixed into the envelopes, starter, and allocation-template controllers so they
# return the same Envelope shape (every query tenant-scoped — ADR-0014).
module EnvelopeRendering
  extend ActiveSupport::Concern

  private

  # The first day of the caller's current month, in their timezone.
  def current_month
    @current_month ||= MonthWindow.current_first_of_month(current_user.timezone)
  end

  # The caller's Expenses (and other rows) that fall within `month`.
  def month_transactions(month)
    tenant_scope(:transactions)
      .where(occurred_on: month..month.end_of_month)
      .to_a
  end

  # `{ envelopes: [...] }` for `month`, each with its spent/remaining — the shape
  # returned by index, starter seeding, and template apply.
  def envelopes_payload(month: current_month)
    txns = month_transactions(month)
    envelopes = tenant_scope(:envelopes).includes(:allocations).order(:id)
    presenters = envelopes.map do |envelope|
      EnvelopeRepresenter.new(EnvelopePresenter.new(envelope, month: month, transactions: txns)).to_hash
    end
    { envelopes: presenters }
  end

  # JSON for a single Envelope for the current month.
  def render_envelope(envelope, status: :ok)
    presenter = EnvelopePresenter.new(envelope, month: current_month, transactions: month_transactions(current_month))
    render json: EnvelopeRepresenter.new(presenter).to_json, status: status
  end
end

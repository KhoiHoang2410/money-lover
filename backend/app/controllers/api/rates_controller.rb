module Api
  # Rate service surface (issue 19): the resolved global+override rates for the
  # current User, plus per-User override management. Tenant-scoped via
  # BaseController — overrides are only ever read/written through current_user,
  # so one User can never see or change another's overrides (ADR-0014).
  class RatesController < BaseController
    # GET /rates — every rate resolved for the caller (override wins, else the
    # global cached value, flagged stale when the last fetch failed).
    def index
      entries = RateService.resolved_entries(current_user)
      render json: { rates: entries.map { |entry| RateEntryRepresenter.new(entry).to_hash } }
    end

    # PUT /rates/:key/override — set the caller's override for one key.
    def set_override
      RateService.set_override(current_user, params[:key], params.require(:value))
      entry = RateService.resolved_entry(current_user, params[:key])
      render json: RateEntryRepresenter.new(entry).to_hash, status: :ok
    end

    # DELETE /rates/:key/override — clear the caller's override (idempotent).
    def clear_override
      RateService.clear_override(current_user, params[:key])
      head :no_content
    end
  end
end

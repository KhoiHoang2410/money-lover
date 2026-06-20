module Api
  # CRUD for the current user's Goals plus the Contribution action (issue 16).
  # Every row is loaded through `current_user.goals` / `current_user.sources`
  # (Tenancy), so another user's goal — or a reference to another user's source —
  # is unreachable: a cross-tenant id yields 404/422, never the data.
  #
  # A Goal's balance and per-line status/shortfall are computed on read by the pure
  # GoalTracker engine from the caller's Transfer transactions (ADR-0007), so the
  # ledger stays the single source of truth for funding. A Contribution
  # (`create_contribution`) records a single `.transfer` from a VND Account into
  # the Goal: the Account is debited and the Goal credited by the same amount, so
  # net worth is unchanged — one Asset becomes another.
  class GoalsController < BaseController
    def index
      transactions = tenant_scope(:transactions).to_a
      goals = tenant_scope(:goals).order(:id)
      render json: { goals: goals.map { |goal| represent(goal, transactions).to_hash } }
    end

    def show
      goal = load_owned!(:goals, params[:id])
      render json: represent(goal, tenant_scope(:transactions).to_a).to_json
    end

    def create
      attrs = validate!(Goals::CreateContract)
      goal = current_user.goals.new
      assign_create(goal, attrs)
      goal.save!
      render json: represent(goal, []).to_json, status: :created
    end

    def update
      goal = load_owned!(:goals, params[:id])
      attrs = validate!(Goals::UpdateContract)
      assign_update(goal, attrs)
      goal.save!
      render json: represent(goal, tenant_scope(:transactions).to_a).to_json
    end

    def destroy
      goal = load_owned!(:goals, params[:id])
      goal.destroy!
      head :no_content
    end

    # POST /api/goals/:goal_id/contributions — fund the Goal from a VND Account.
    # Realized as a single Transfer (kind: transfer, source: the Account, no
    # destination, tagged with this goal_id) committed atomically: the Account is
    # debited and the Goal credited by the same amount (ADR-0007).
    def create_contribution
      goal = load_owned!(:goals, params[:goal_id])
      attrs = validate!(Contributions::CreateContract)
      source = owned_vnd_account!(attrs[:source_id])

      ActiveRecord::Base.transaction do
        current_user.transactions.create!(
          kind: Transaction::TRANSFER,
          source: source,
          destination: nil,
          amount_minor_units: attrs[:amount_minor_units],
          currency: Source::BASE_CURRENCY,
          goal_id: goal.id,
          occurred_on: attrs[:occurred_on] || Date.current,
          note: attrs[:note],
          backfill: false
        )
      end

      render json: represent(goal, tenant_scope(:transactions).to_a).to_json, status: :created
    end

    private

    def represent(goal, transactions)
      GoalRepresenter.new(GoalPresenter.new(goal, transactions: transactions, as_of: as_of))
    end

    # "Today" in the User's timezone (CONTEXT.md): timezone defines month
    # boundaries and "today" for the Schedule status engine.
    def as_of
      zone = ActiveSupport::TimeZone[current_user.timezone] || ActiveSupport::TimeZone["UTC"]
      zone.today
    end

    # Runs a dry-validation contract over the permitted params, raising a
    # structured 422 (ApiError::Validation → render_validation) on failure.
    def validate!(contract_class)
      result = contract_class.new.call(contract_params(contract_class))
      return result.to_h if result.success?

      raise ApiError::Validation.new("Goal params are invalid.", details: result.errors.to_h)
    end

    def contract_params(contract_class)
      if contract_class == Contributions::CreateContract
        params.permit(:source_id, :amount_minor_units, :currency, :occurred_on, :note).to_h
      else
        params.permit(
          :name, :icon, :currency, :target_minor_units,
          start_month: %i[year month],
          end_month: %i[year month],
          schedule: %i[year month amount_minor_units]
        ).to_h
      end
    end

    def assign_create(goal, attrs)
      goal.name = attrs[:name]
      goal.icon = attrs[:icon]
      goal.currency = attrs[:currency] || Source::BASE_CURRENCY
      goal.target_minor_units = attrs[:target_minor_units]
      assign_window(goal, attrs)
      goal.schedule = normalize_schedule(attrs[:schedule])
    end

    def assign_update(goal, attrs)
      goal.name = attrs[:name] if attrs.key?(:name)
      goal.icon = attrs[:icon] if attrs.key?(:icon)
      goal.target_minor_units = attrs[:target_minor_units] if attrs.key?(:target_minor_units)
      assign_window(goal, attrs)
      goal.schedule = normalize_schedule(attrs[:schedule]) if attrs.key?(:schedule)
    end

    def assign_window(goal, attrs)
      if attrs.key?(:start_month)
        goal.start_year = attrs[:start_month][:year]
        goal.start_month = attrs[:start_month][:month]
      end
      return unless attrs.key?(:end_month)

      goal.end_year = attrs[:end_month][:year]
      goal.end_month = attrs[:end_month][:month]
    end

    # The Schedule is stored as a JSON array of string-keyed lines, mirroring how
    # it reads back from the jsonb column.
    def normalize_schedule(lines)
      Array(lines).map do |line|
        {
          "year" => line[:year],
          "month" => line[:month],
          "amount_minor_units" => line[:amount_minor_units]
        }
      end
    end

    # Loads one of the caller's sources and enforces the funding rule (CONTEXT.md
    # "Contribution"): a Goal is funded from a VND Account only. A missing /
    # cross-tenant source, a non-Account source, or a foreign-currency Account each
    # raises a 422 (not a 404) for the reference in the body.
    def owned_vnd_account!(id)
      source = current_user.sources.find_by(id: id)
      unless source
        raise ApiError::Validation.new("Contribution params are invalid.",
                                       details: { source_id: [ "must reference one of your sources" ] })
      end

      unless source.kind == Source::ACCOUNT && source.currency == Source::BASE_CURRENCY
        raise ApiError::Validation.new("Contribution params are invalid.",
                                       details: { source_id: [ "must be a VND account" ] })
      end

      source
    end
  end
end

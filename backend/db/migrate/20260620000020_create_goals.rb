class CreateGoals < ActiveRecord::Migration[8.0]
  def change
    # A Goal (CONTEXT.md): a long-term savings target with a funding window
    # (start month → end month) and a planned Schedule. User-scoped — every row is
    # owned by exactly one User and only ever reached through that association
    # (Tenancy concern, ADR-0014). A Goal holds a real balance, the accumulated
    # Contributions, but that balance is NOT stored here: it is derived from the
    # ledger (Σ of the `.transfer` transactions tagged with this goal's id), so the
    # transaction table stays the single source of truth for goal funding
    # (ADR-0007). The pure GoalTracker engine computes progress/status/shortfall.
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true

      t.string :name, null: false
      t.string :icon

      # The savings target in integer minor units + a currency (VND-only for now,
      # CONTEXT.md "Goal"). Never a float (ADR-0015).
      t.bigint :target_minor_units, null: false
      t.string :currency, null: false, default: "VND"

      # The funding window is month-based, not day-based (Contributions happen
      # monthly): a start month and an end month, each a (year, month) pair.
      t.integer :start_year
      t.integer :start_month
      t.integer :end_year
      t.integer :end_month

      # The Schedule (CONTEXT.md): a list of month → planned amount, stored as a
      # JSON array of { "year", "month", "amount_minor_units" } lines. Need not be
      # flat or continuous; a line is a *plan*, distinct from an actual
      # Contribution. Amounts are integer minor units in the goal's currency.
      t.jsonb :schedule, null: false, default: []

      t.timestamps
    end
  end
end

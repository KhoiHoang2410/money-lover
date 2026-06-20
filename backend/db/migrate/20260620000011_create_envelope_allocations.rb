class CreateEnvelopeAllocations < ActiveRecord::Migration[8.0]
  def change
    # Per-month Allocation history (PRD § envelopes; issue 10's deferred-decision
    # resolution): the month-end sweep is derived-on-read from stored per-month
    # Allocation snapshots rather than a stateful cron, so the schema records one
    # snapshot per Envelope per month. An Allocation template "apply" seeds these
    # rows for a month; an Envelope's effective Allocation for a month is its
    # snapshot here, falling back to the Envelope default when absent.
    create_table :envelope_allocations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :envelope, null: false, foreign_key: true

      # The first day of the month this Allocation applies to (the User's month
      # boundary; User.timezone drives "which month", ADR-0014).
      t.date :month, null: false

      t.bigint :allocation_minor_units, null: false, default: 0
      t.string :currency, null: false

      t.timestamps
    end

    # One snapshot per Envelope per month (apply is idempotent — it upserts).
    add_index :envelope_allocations, [ :envelope_id, :month ], unique: true
    add_index :envelope_allocations, [ :user_id, :month ]
  end
end

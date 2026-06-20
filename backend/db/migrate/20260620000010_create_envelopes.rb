class CreateEnvelopes < ActiveRecord::Migration[8.0]
  def change
    # An Envelope (CONTEXT.md): a named virtual bucket income is divided into.
    # User-scoped — every row is owned by exactly one User and only ever reached
    # through that association (Tenancy concern, ADR-0014). Money is integer minor
    # units + a currency code, never a float (ADR-0015).
    create_table :envelopes do |t|
      t.references :user, null: false, foreign_key: true

      t.string :name, null: false
      t.string :icon

      # The Reserve is the single Envelope marked as default; month-end leftovers
      # sweep into it and it never resets (CONTEXT.md "Reserve"). At most one per
      # User — enforced by the partial unique index below and the model.
      t.boolean :is_reserve, null: false, default: false

      # Working currency for this Envelope's Allocation / caps / carried.
      t.string :currency, null: false

      # The default monthly Allocation (the Allocation-template default for this
      # Envelope) in integer minor units. A given month's effective Allocation is
      # the per-month snapshot in envelope_allocations, falling back to this.
      t.bigint :allocation_minor_units, null: false, default: 0

      # Optional weekly / monthly spending caps (guardrails), in minor units.
      t.bigint :weekly_cap_minor_units
      t.bigint :monthly_cap_minor_units

      # Accumulated carry: the Reserve's running balance, or a non-Reserve
      # Envelope's roll-over. Added to the Allocation when computing remaining.
      t.bigint :carried_minor_units, null: false, default: 0

      t.timestamps
    end

    # At most one Reserve per User (the "exactly one Reserve" invariant).
    add_index :envelopes, :user_id, unique: true, where: "is_reserve",
                                    name: "index_envelopes_one_reserve_per_user"
  end
end

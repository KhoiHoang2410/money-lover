class CreateRateOverrides < ActiveRecord::Migration[8.0]
  def change
    # Per-User manual override of a global Rate (CONTEXT.md "Rate"). It wins for
    # that User's valuations only and never affects another User. One row per
    # (user, key); tenant-owned (Tenanted concern, ADR-0014).
    create_table :rate_overrides do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false

      # Same exact-VND semantics as rates.value — never a Float (ADR-0015).
      t.decimal :value, precision: 30, scale: 10, null: false

      t.timestamps
    end

    add_index :rate_overrides, [ :user_id, :key ], unique: true
  end
end

class CreateSources < ActiveRecord::Migration[8.0]
  def change
    # A money source (CONTEXT.md): an Account or Credit card (a money balance) or
    # a Holding (anchored on an opening quantity, not money). User-scoped — every
    # row is owned by exactly one User and only ever reached through that
    # association (Tenancy concern, ADR-0014).
    create_table :sources do |t|
      t.references :user, null: false, foreign_key: true

      # account | credit_card | holding (CONTEXT.md "Account"/"Credit card"/"Holding").
      t.string :kind, null: false
      t.string :name, null: false
      t.string :icon
      # Optional logo asset reference (issue 13 scope).
      t.string :logo

      # Native currency. VND for Holdings (the base currency); the held currency
      # for an Account/Credit card.
      t.string :currency, null: false

      # Opening money balance in integer minor units (ADR-0015) — never a float.
      # Present for Account/Credit card (the anchor for all balance math);
      # null for a Holding, which anchors on an opening quantity instead.
      t.bigint :opening_minor_units

      # Holding fields: exact opening quantity (decimal, never float — ADR-0015),
      # its unit (chi | luong | shares) and, for a stock, its HOSE ticker.
      t.decimal :opening_quantity, precision: 30, scale: 10
      t.string :holding_unit
      t.string :ticker

      t.timestamps
    end

    add_index :sources, [ :user_id, :kind ]
  end
end

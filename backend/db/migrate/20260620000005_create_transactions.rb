class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    # A Transaction (CONTEXT.md): an Expense, Income, Transfer, Invest or
    # Adjustment owned by exactly one User and only ever reached through that
    # association (Tenancy concern, ADR-0014). Money is integer minor units +
    # a currency code — never a float (ADR-0015). Balances are computed on read
    # (opening + Σ transactions) by BalanceEngine, so a row is the single source
    # of every ledger delta it implies; nothing here mutates a source balance
    # except an explicit Backfill restatement (ADR-0012).
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true

      # expense | income | transfer | invest | adjustment (CONTEXT.md "Transactions").
      t.string :kind, null: false

      # The primary source the money leaves/affects. Always present.
      t.references :source, null: false, foreign_key: { to_table: :sources }
      # The receiving source for a Transfer / the Holding for an Invest. Null otherwise.
      t.references :destination, foreign_key: { to_table: :sources }

      # The transaction amount in the source currency, integer minor units.
      # For an Adjustment this is the SIGNED reconcile delta (ADR-0015).
      t.bigint :amount_minor_units, null: false
      t.string :currency, null: false

      # Cross-currency Transfer (CONTEXT.md "Transfer"): the amount that lands in
      # the destination, in the destination currency; the manually-entered Rate;
      # and the computed Fee = (amount_out × rate) − amount_in (TransferFxMath),
      # in the destination currency. Null for a same-currency move.
      t.bigint :destination_amount_minor_units
      t.string :destination_currency
      t.decimal :manual_rate, precision: 30, scale: 10
      t.bigint :fee_minor_units

      # Invest trade legs (CONTEXT.md "Invest"): exact units transacted (never a
      # float — ADR-0015) and the buy/sell direction.
      t.decimal :trade_quantity, precision: 30, scale: 10
      t.string :trade_direction

      # Budgeting / Goals references (issues 16/17). Stored as plain ids until
      # those tables land; an Expense/Adjustment carries an Envelope, a Goal
      # Contribution carries a Goal.
      t.bigint :envelope_id
      t.bigint :goal_id

      t.string :note

      # The date the money moved (CONTEXT.md), drives the calendar and date-range
      # filters. Defaults to the create date in the controller when omitted.
      t.date :occurred_on, null: false

      # True when this row was logged as a Backfill — recording it restated its
      # source's opening balance so the current balance stayed unchanged (ADR-0012).
      t.boolean :backfill, null: false, default: false

      t.timestamps
    end

    add_index :transactions, [ :user_id, :occurred_on ]
    add_index :transactions, [ :user_id, :kind ]
    add_index :transactions, :envelope_id
  end
end

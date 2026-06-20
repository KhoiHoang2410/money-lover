class CreateRates < ActiveRecord::Migration[8.0]
  def change
    # Global market rates shared by all Users (CONTEXT.md "Rate"). Auto-fetched
    # and cached by scheduled jobs; one row per key (fx.USD, fx.SGD, gold,
    # stock.<TICKER>).
    create_table :rates do |t|
      t.string :key, null: false

      # The exact price in VND, never a Float (ADR-0015): VND per 1 major unit
      # for fx.*, VND per chỉ for gold, VND per share for stock.*. Stored as a
      # wide decimal so it reads back as an exact BigDecimal for Money math.
      t.decimal :value, precision: 30, scale: 10, null: false

      # Where the value came from (e.g. "fx", "sjc", "hose") and when it was
      # last successfully fetched.
      t.string :source
      t.datetime :fetched_at

      # Set true when the latest fetch failed and we are serving the last good
      # cached value (CONTEXT.md "Rate": stale fallback).
      t.boolean :stale, null: false, default: false

      t.timestamps
    end

    add_index :rates, :key, unique: true
  end
end

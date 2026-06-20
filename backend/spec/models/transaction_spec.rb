require "rails_helper"

# Transaction is the persistence edge for a ledger row: it maps stored minor
# units / quantity into the pure `BalanceEngine::Transaction` / `Invest` value
# objects the engines consume (no Float crosses the boundary — ADR-0015).
RSpec.describe Transaction, type: :model do
  let(:user) { User.create!(timezone: User::DEFAULT_TIMEZONE) }
  let(:acct) do
    user.sources.create!(kind: "account", name: "VPBank", currency: "VND", opening_minor_units: 0)
  end
  let(:holding) do
    user.sources.create!(kind: "holding", name: "VNM", currency: "VND",
                         opening_quantity: "10", holding_unit: "shares", ticker: "VNM")
  end

  it "exposes the amount as Money in the source currency" do
    txn = user.transactions.create!(kind: "expense", source: acct, amount_minor_units: 250_000,
                                    currency: "VND", occurred_on: Date.new(2026, 1, 1))

    expect(txn.amount).to eq(Money.new(minor_units: 250_000, currency: :VND))
  end

  it "maps an expense to a BalanceEngine::Transaction the engine signs as a debit" do
    txn = user.transactions.create!(kind: "expense", source: acct, amount_minor_units: 250_000,
                                    currency: "VND", occurred_on: Date.new(2026, 1, 1))

    engine_source = BalanceEngine::Source.build(id: acct.id, kind: acct.kind, currency: acct.currency,
                                                opening_balance: acct.opening_balance)
    delta = BalanceEngine.delta_for(engine_source, txn.to_balance_txn)
    expect(delta).to eq(Money.new(minor_units: -250_000, currency: :VND))
  end

  it "builds an Invest value object for a trade and nil otherwise" do
    sell = user.transactions.create!(kind: "invest", source: acct, destination: holding,
                                     amount_minor_units: 600_000, currency: "VND",
                                     trade_quantity: "4", trade_direction: "sell",
                                     occurred_on: Date.new(2026, 1, 1))
    expense = user.transactions.create!(kind: "expense", source: acct, amount_minor_units: 1,
                                        currency: "VND", occurred_on: Date.new(2026, 1, 1))

    invest = sell.to_invest
    expect(invest.sell?).to be(true)
    expect(invest.quantity).to eq(Rational(4))
    expect(invest.destination_id).to eq(holding.id)
    expect(expense.to_invest).to be_nil
  end

  it "exposes a cross-currency transfer's destination amount and fee as Money" do
    vnd = user.sources.create!(kind: "account", name: "VPBank2", currency: "VND", opening_minor_units: 0)
    txn = user.transactions.create!(kind: "transfer", source: acct, destination: vnd,
                                    amount_minor_units: 10_000, currency: "VND",
                                    destination_amount_minor_units: 1_690_000, destination_currency: "VND",
                                    fee_minor_units: 10_000, occurred_on: Date.new(2026, 1, 1))

    expect(txn.destination_amount).to eq(Money.new(minor_units: 1_690_000, currency: :VND))
    expect(txn.fee).to eq(Money.new(minor_units: 10_000, currency: :VND))
  end

  it "validates kind and currency" do
    txn = user.transactions.new(kind: "gift", source: acct, occurred_on: Date.current)

    expect(txn).not_to be_valid
    expect(txn.errors.attribute_names).to include(:kind, :currency)
  end
end

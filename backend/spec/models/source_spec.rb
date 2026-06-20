require "rails_helper"

# Source is the persistence edge for a money source: it maps stored minor units /
# quantity into the pure `Money` / `Quantity` / `Holding` domain objects the
# engines consume (no Float crosses the boundary — ADR-0015).
RSpec.describe Source, type: :model do
  let(:user) { User.create!(timezone: User::DEFAULT_TIMEZONE) }

  it "exposes a money source's opening balance as Money" do
    source = user.sources.create!(kind: "account", name: "VPBank",
                                  currency: "VND", opening_minor_units: 1_000_000)

    expect(source.opening_balance).to eq(Money.new(minor_units: 1_000_000, currency: :VND))
    expect(source.account_like?).to be(true)
    expect(source.holding_facts).to be_nil
  end

  it "treats a credit card opening balance as a (signed) liability" do
    card = user.sources.create!(kind: "credit_card", name: "VIB",
                                currency: "VND", opening_minor_units: -500_000)

    expect(card.opening_balance.minor_units).to eq(-500_000)
    expect(card.account_like?).to be(true)
  end

  it "exposes a gold holding's facts as a Quantity + Holding, with no money balance" do
    gold = user.sources.create!(kind: "holding", name: "SJC Gold",
                                currency: "VND", opening_quantity: "3", holding_unit: "chi")

    expect(gold.opening_balance).to be_nil
    expect(gold.opening_quantity_value).to eq(Quantity.new("3", unit: :chi))
    expect(gold.holding_facts.gold?).to be(true)
  end

  it "exposes a stock holding's ticker" do
    stock = user.sources.create!(kind: "holding", name: "VNM", currency: "VND",
                                 opening_quantity: "120", holding_unit: "shares", ticker: "VNM")

    expect(stock.holding_facts.gold?).to be(false)
    expect(stock.holding_facts.ticker).to eq("VNM")
  end

  it "validates kind, name and currency" do
    source = user.sources.new(kind: "wallet")

    expect(source).not_to be_valid
    expect(source.errors.attribute_names).to include(:kind, :name, :currency)
  end
end

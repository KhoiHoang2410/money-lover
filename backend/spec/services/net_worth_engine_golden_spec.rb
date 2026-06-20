# frozen_string_literal: true

require "rails_helper"

# Parity oracle: drives `NetWorthEngine` against the shared, language-neutral
# `net_worth.json` golden fixture (issue 03 / ADR-0015) with exact-equality
# assertions, then pins the two conservation invariants (Contribution and Invest
# preserve net worth) as unit properties.
RSpec.describe NetWorthEngine do
  describe "golden fixtures (net_worth.json)" do
    doc = GoldenFixtures.load("net_worth")

    def build_entry(node)
      source = node.fetch("source")
      NetWorthEngine::Entry.build(
        kind: source.fetch("kind"),
        currency: source.fetch("currency"),
        balance: GoldenFixtures.money(node.fetch("balance")),
        holding: GoldenFixtures.holding(source["holding"])
      )
    end

    doc["cases"].each do |c|
      it "reproduces #{c['name']} byte-identically" do
        inputs = c["inputs"]

        result = described_class.compute(
          entries: inputs.fetch("entries").map { |e| build_entry(e) },
          goal_balances: inputs.fetch("goal_balances").map { |m| GoldenFixtures.money(m) },
          rates: GoldenFixtures.rates(inputs.fetch("rates"))
        )

        expected = c["expected_outputs"]
        expect(result.asset).to eq(GoldenFixtures.money(expected.fetch("asset")))
        expect(result.debt).to eq(GoldenFixtures.money(expected.fetch("debt")))
        expect(result.net).to eq(GoldenFixtures.money(expected.fetch("net")))
      end
    end

    it "covers every fixture case" do
      expect(doc["cases"].size).to eq(5)
    end
  end

  describe "conservation invariants" do
    let(:rates) do
      Rates.new(fx: { VND: 1, USD: 25_500 }, gold_per_chi: 15_950_000, stock: {})
    end

    def vnd(minor) = Money.new(minor_units: minor, currency: :VND)

    def account(minor)
      NetWorthEngine::Entry.build(kind: :account, currency: :VND, balance: vnd(minor))
    end

    it "leaves net unchanged when a Contribution moves Account → Goal" do
      before = described_class.compute(entries: [ account(60_000_000) ], rates: rates)

      # Contribute 40M: the Account drops, the Goal balance rises by the same amount.
      after = described_class.compute(
        entries: [ account(20_000_000) ],
        goal_balances: [ vnd(40_000_000) ],
        rates: rates
      )

      expect(after.net).to eq(before.net)
      expect(after.net).to eq(vnd(60_000_000))
    end

    it "leaves net unchanged when an Invest trade moves Account ↔ Holding" do
      before = described_class.compute(entries: [ account(100_000_000) ], rates: rates)

      # Buy 5 chỉ of gold at ₫15,950,000/chỉ = ₫79,750,000 out of the Account.
      holding = Holding.new(quantity: Quantity.new("5", unit: :chi))
      after = described_class.compute(
        entries: [
          account(100_000_000 - 79_750_000),
          NetWorthEngine::Entry.build(kind: :holding, currency: :VND, balance: vnd(0), holding: holding)
        ],
        rates: rates
      )

      expect(after.net).to eq(before.net)
      expect(after.net).to eq(vnd(100_000_000))
    end

    it "classifies an overdrawn foreign Account into Debt by sign, not kind" do
      result = described_class.compute(
        entries: [
          NetWorthEngine::Entry.build(kind: :account, currency: :USD, balance: Money.new(minor_units: -20_000, currency: :USD))
        ],
        rates: rates
      )

      expect(result.asset).to eq(vnd(0))
      expect(result.debt).to eq(vnd(-5_100_000))
      expect(result.net).to eq(vnd(-5_100_000))
    end
  end
end

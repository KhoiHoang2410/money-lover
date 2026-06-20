# frozen_string_literal: true

require "rails_helper"

# Drives the Valuator against the shared golden `valuation.json` fixture with
# exact-equality assertions (ADR-0015 parity oracle), plus a few unit cases that
# pin the degrade-to-₫0 behaviour the Swift `Core` guarantees.
RSpec.describe Valuator do
  describe "golden fixtures (valuation.json)" do
    doc = GoldenFixtures.load("valuation")

    doc["cases"].each do |c|
      it "reproduces #{c['name']} byte-identically" do
        inputs = c["inputs"]
        source = inputs["source"]

        result = described_class.value_in_vnd(
          kind: source["kind"],
          currency: source["currency"],
          balance: GoldenFixtures.money(inputs["balance"]),
          rates: GoldenFixtures.rates(inputs["rates"]),
          holding: GoldenFixtures.holding(source["holding"])
        )

        expect(result).to eq(GoldenFixtures.money(c["expected_outputs"]["value_vnd"]))
      end
    end

    it "covers every fixture case" do
      expect(doc["cases"].size).to eq(12)
    end
  end

  describe "unit behaviour" do
    let(:rates) do
      Rates.new(fx: { VND: 1, USD: 25_500 }, gold_per_chi: 15_950_000, stock: { "FPT" => 72_000 })
    end

    it "is the identity for a VND account" do
      result = described_class.value_in_vnd(
        kind: :account, currency: :VND,
        balance: Money.new(minor_units: 80_000_000, currency: :VND), rates: rates
      )
      expect(result).to eq(Money.new(minor_units: 80_000_000, currency: :VND))
    end

    it "converts a foreign account by its FX rate" do
      result = described_class.value_in_vnd(
        kind: :account, currency: :USD,
        balance: Money.new(minor_units: 110_000, currency: :USD), rates: rates
      )
      expect(result).to eq(Money.new(minor_units: 28_050_000, currency: :VND))
    end

    it "prices a lượng gold holding as ten chỉ" do
      holding = Holding.new(quantity: Quantity.new("1", unit: :luong))
      result = described_class.value_in_vnd(
        kind: :holding, currency: :VND,
        balance: Money.zero(:VND), rates: rates, holding: holding
      )
      expect(result).to eq(Money.new(minor_units: 159_500_000, currency: :VND))
    end

    it "degrades a missing FX rate to ₫0 (never raises)" do
      result = described_class.value_in_vnd(
        kind: :account, currency: :SGD,
        balance: Money.new(minor_units: 200_000, currency: :SGD), rates: rates
      )
      expect(result).to eq(Money.zero(:VND))
    end

    it "degrades an unknown ticker to ₫0" do
      holding = Holding.new(quantity: Quantity.new("500", unit: :shares), ticker: "UNKNOWN")
      result = described_class.value_in_vnd(
        kind: :holding, currency: :VND,
        balance: Money.zero(:VND), rates: rates, holding: holding
      )
      expect(result).to eq(Money.zero(:VND))
    end

    it "values a holding source with missing facts as ₫0" do
      result = described_class.value_in_vnd(
        kind: :holding, currency: :VND,
        balance: Money.zero(:VND), rates: rates, holding: nil
      )
      expect(result).to eq(Money.zero(:VND))
    end

    it "keeps credit-card debt negative in VND" do
      result = described_class.value_in_vnd(
        kind: :credit_card, currency: :VND,
        balance: Money.new(minor_units: -18_300_000, currency: :VND), rates: rates
      )
      expect(result).to eq(Money.new(minor_units: -18_300_000, currency: :VND))
    end
  end
end

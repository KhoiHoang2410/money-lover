require "rails_helper"

# Locks down the edge mapping between persisted/serialized columns (bigint
# minor units + currency code) and the Money value object (ADR-0015): the
# round-trip is lossless and no Float ever crosses the edge.
RSpec.describe MoneyMapping do
  describe ".dump" do
    it "serializes Money to a primitive minor-units + currency-code hash" do
      money = Money.new(minor_units: 40_000, currency: :VND)
      expect(described_class.dump(money)).to eq(minor_units: 40_000, currency: "VND")
    end
  end

  describe ".load" do
    it "reconstructs Money from an integer bigint and currency code" do
      expect(described_class.load(minor_units: 150, currency: "USD"))
        .to eq(Money.new(minor_units: 150, currency: :USD))
    end

    it "accepts a numeric String (e.g. from a JSON body) as exact bigint" do
      expect(described_class.load(minor_units: "150", currency: "USD"))
        .to eq(Money.new(minor_units: 150, currency: :USD))
    end

    it "rejects a Float (no float crosses the edge)" do
      expect { described_class.load(minor_units: 150.0, currency: "USD") }
        .to raise_error(MoneyError::InexactValue)
    end

    it "rejects an unknown currency" do
      expect { described_class.load(minor_units: 1, currency: "BTC") }
        .to raise_error(ArgumentError, /unknown currency/)
    end
  end

  describe "round-trip" do
    it "dump → load reconstructs an equal Money" do
      original = Money.new(minor_units: -28_050_000, currency: :VND)
      restored = described_class.load(**described_class.dump(original))
      expect(restored).to eq(original)
    end
  end
end

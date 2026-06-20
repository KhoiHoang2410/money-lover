require "rails_helper"

# Locks down the exact holding-quantity type (ADR-0015): quantity is a SEPARATE
# exact type from Money, backed by a Rational so `quantity × price` stays exact.
# Float never enters; gold units convert via the exact 1 lượng = 10 chỉ factor.
RSpec.describe Quantity do
  describe "construction & invariants" do
    it "stores an integer value exactly" do
      expect(described_class.new(5, unit: :chi).value).to eq(Rational(5))
    end

    it "parses a decimal string exactly (no float drift)" do
      expect(described_class.new("0.1", unit: :shares).value).to eq(Rational(1, 10))
    end

    it "accepts a BigDecimal as exact" do
      expect(described_class.new(BigDecimal("2.5"), unit: :chi).value).to eq(Rational(5, 2))
    end

    it "rejects a Float (no float in quantity math)" do
      expect { described_class.new(0.1, unit: :shares) }
        .to raise_error(MoneyError::InexactValue)
    end

    it "normalizes the unit to a lower-case symbol" do
      expect(described_class.new(1, unit: "LUONG").unit).to eq(:luong)
    end

    it "raises on an unknown unit" do
      expect { described_class.new(1, unit: :ounces) }
        .to raise_error(ArgumentError, /unknown holding unit/)
    end

    it "is frozen (immutable value object)" do
      expect(described_class.zero(unit: :shares)).to be_frozen
    end
  end

  describe "same-unit arithmetic (exact)" do
    it "adds within a unit" do
      expect(described_class.new(2, unit: :chi).add(described_class.new(3, unit: :chi)))
        .to eq(described_class.new(5, unit: :chi))
    end

    it "subtracts within a unit, going negative" do
      expect(described_class.new(2, unit: :shares).subtract(described_class.new(5, unit: :shares)))
        .to eq(described_class.new(-3, unit: :shares))
    end

    it "scales by an exact factor without drift" do
      expect(described_class.new("0.1", unit: :shares).scale(3).value).to eq(Rational(3, 10))
    end

    it "raises on a unit mismatch (never silently coerces)" do
      expect { described_class.new(1, unit: :chi).add(described_class.new(1, unit: :luong)) }
        .to raise_error(ArgumentError)
    end
  end

  describe "gold unit conversion (1 lượng = 10 chỉ, exact)" do
    it "expresses lượng in chỉ" do
      expect(described_class.new("2.5", unit: :luong).in_chi).to eq(Rational(25))
    end

    it "leaves chỉ unchanged" do
      expect(described_class.new(7, unit: :chi).in_chi).to eq(Rational(7))
    end
  end

  describe "comparison (Comparable)" do
    it "orders within a unit" do
      expect(described_class.new(1, unit: :chi)).to be < described_class.new(2, unit: :chi)
    end

    it "treats same magnitude / different unit as unequal" do
      expect(described_class.new(1, unit: :chi)).not_to eq(described_class.new(1, unit: :luong))
    end

    it "raises when ordering across units" do
      expect { described_class.new(1, unit: :chi) < described_class.new(1, unit: :luong) }
        .to raise_error(ArgumentError)
    end
  end
end

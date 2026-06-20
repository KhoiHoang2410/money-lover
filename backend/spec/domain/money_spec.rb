require "rails_helper"

# Locks down the integer-minor-unit money primitive (ADR-0015): exact integer
# arithmetic, same-currency-only add/subtract, sum, and half-away-from-zero
# rounding on `from_major`/`convert` — the boundary `.5` cases mirror the Swift
# `Core` (ios/MoneyLover/Core/Money.swift + MoneyTests.swift).
RSpec.describe Money do
  describe "construction & invariants" do
    it "rejects non-integer minor_units (no Float ever)" do
      expect { described_class.new(minor_units: 1.5, currency: :USD) }
        .to raise_error(MoneyError::InexactValue)
    end

    it "normalizes the currency to an upper-case symbol" do
      expect(described_class.new(minor_units: 100, currency: "usd").currency).to eq(:USD)
    end

    it "raises on an unknown currency" do
      expect { described_class.new(minor_units: 100, currency: :BTC) }
        .to raise_error(ArgumentError, /unknown currency/)
    end

    it "is frozen (immutable value object)" do
      expect(described_class.zero(:VND)).to be_frozen
    end
  end

  describe "same-currency arithmetic (exact integer)" do
    it "adds minor units" do
      expect(described_class.new(minor_units: 100, currency: :VND)
        .add(described_class.new(minor_units: 250, currency: :VND)))
        .to eq(described_class.new(minor_units: 350, currency: :VND))
    end

    it "subtracts minor units, going negative" do
      diff = described_class.new(minor_units: 200, currency: :USD)
        .subtract(described_class.new(minor_units: 500, currency: :USD))
      expect(diff.minor_units).to eq(-300)
      expect(diff).to be_negative
    end

    it "negates, preserving currency and round-tripping" do
      n = described_class.new(minor_units: 40_000, currency: :VND).negate
      expect(n).to eq(described_class.new(minor_units: -40_000, currency: :VND))
      expect(n.negate).to eq(described_class.new(minor_units: 40_000, currency: :VND))
    end

    it "exposes + and - and unary - aliases" do
      a = described_class.new(minor_units: 30, currency: :USD)
      b = described_class.new(minor_units: 12, currency: :USD)
      expect((a + b).minor_units).to eq(42)
      expect((a - b).minor_units).to eq(18)
      expect((-a).minor_units).to eq(-30)
    end

    # The classic float trap (0.10 + 0.20) — defeated by integer cents.
    it "never drifts on awkward cent sums" do
      sum = described_class.from_major("0.10", :USD).add(described_class.from_major("0.20", :USD))
      expect(sum.minor_units).to eq(30)
      expect(sum.amount).to eq(Rational(3, 10))
    end
  end

  describe "currency mismatch raises (never silently coerces)" do
    it "raises on add across currencies" do
      expect do
        described_class.new(minor_units: 100, currency: :VND)
          .add(described_class.new(minor_units: 100, currency: :USD))
      end.to raise_error(MoneyError::CurrencyMismatch)
    end

    it "raises on subtract across currencies" do
      expect do
        described_class.new(minor_units: 100, currency: :SGD)
          .subtract(described_class.new(minor_units: 100, currency: :VND))
      end.to raise_error(MoneyError::CurrencyMismatch)
    end
  end

  describe "comparison (Comparable)" do
    it "orders within a currency" do
      small = described_class.new(minor_units: 100, currency: :USD)
      big = described_class.new(minor_units: 250, currency: :USD)
      expect(small).to be < big
      expect([ big, small ].min).to eq(small)
    end

    it "treats same number / different currency as unequal" do
      expect(described_class.new(minor_units: 100, currency: :VND))
        .not_to eq(described_class.new(minor_units: 100, currency: :USD))
    end

    it "raises (not silently coerces) when ordering across currencies" do
      expect do
        described_class.new(minor_units: 100, currency: :VND) <
          described_class.new(minor_units: 100, currency: :USD)
      end.to raise_error(ArgumentError)
    end
  end

  describe ".sum over a collection" do
    it "sums same-currency money" do
      monies = [ 100, 250, 50 ].map { |m| described_class.new(minor_units: m, currency: :VND) }
      expect(described_class.sum(monies)).to eq(described_class.new(minor_units: 400, currency: :VND))
    end

    it "returns zero for an empty collection when given a currency" do
      expect(described_class.sum([], currency: :USD)).to eq(described_class.zero(:USD))
    end

    it "raises for an empty collection without a currency" do
      expect { described_class.sum([]) }.to raise_error(ArgumentError)
    end

    it "raises on a currency mismatch inside the collection" do
      monies = [ described_class.new(minor_units: 1, currency: :VND),
                described_class.new(minor_units: 1, currency: :USD) ]
      expect { described_class.sum(monies) }.to raise_error(MoneyError::CurrencyMismatch)
    end

    it "validates every element against an explicit currency" do
      monies = [ described_class.new(minor_units: 1, currency: :USD) ]
      expect { described_class.sum(monies, currency: :VND) }
        .to raise_error(MoneyError::CurrencyMismatch)
    end
  end

  # Rounding parity with Swift Money(major:) → NSRoundPlain (half away from zero).
  # Table mirrors MoneyTests.majorInitRoundsToMinorGrid in the iOS Core.
  describe ".from_major rounding (half away from zero — mirrors Swift NSRoundPlain)" do
    {
      [ :VND, "40000" ] => 40_000,
      [ :VND, "40000.4" ] => 40_000, # VND has no fraction → rounds toward nearest
      [ :VND, "40000.6" ] => 40_001,
      [ :USD, "1.50" ] => 150,
      [ :USD, "1.005" ] => 101,      # 100.5 minor → ties round AWAY from zero → 101
      [ :USD, "1.999" ] => 200,
      [ :SGD, "0.001" ] => 0
    }.each do |(currency, major), expected|
      it "#{major} #{currency} -> #{expected} minor" do
        expect(described_class.from_major(major, currency).minor_units).to eq(expected)
      end
    end

    it "rounds negative ties away from zero (-100.5 minor -> -101)" do
      expect(described_class.from_major("-1.005", :USD).minor_units).to eq(-101)
    end

    it "accepts an exact Rational major without float drift" do
      expect(described_class.from_major(Rational(1, 3), :USD).minor_units).to eq(33)
    end

    it "rejects a Float major (no float in money math)" do
      expect { described_class.from_major(1.005, :USD) }.to raise_error(MoneyError::InexactValue)
    end
  end

  describe "#convert via an exact rate (used by Valuator / TransferFxMath)" do
    it "converts USD to VND by an integer rate (mirrors Valuator FX)" do
      # $1,100 × 25,500 = ₫28,050,000 (cf. ValuatorTests.usdAccountConvertsByFX)
      usd = described_class.new(minor_units: 1_100_00, currency: :USD)
      expect(usd.convert(to: :VND, rate: 25_500))
        .to eq(described_class.new(minor_units: 28_050_000, currency: :VND))
    end

    it "rounds a conversion tie half away from zero" do
      # S$0.01 × 0.5 = $0.005 → 0.5 minor → 1 cent (away from zero).
      sgd = described_class.new(minor_units: 1, currency: :SGD)
      expect(sgd.convert(to: :USD, rate: "0.5").minor_units).to eq(1)
    end

    it "rounds a negative conversion tie away from zero" do
      sgd = described_class.new(minor_units: -1, currency: :SGD)
      expect(sgd.convert(to: :USD, rate: "0.5").minor_units).to eq(-1)
    end

    it "rejects a Float rate" do
      usd = described_class.new(minor_units: 100, currency: :USD)
      expect { usd.convert(to: :VND, rate: 25_500.0) }.to raise_error(MoneyError::InexactValue)
    end
  end
end

# frozen_string_literal: true

require "bigdecimal"

# An exact monetary amount, stored as integer minor units in a single currency.
#
# This is the canonical money primitive every engine and representer uses, so
# Float never enters money math (ADR-0015). It is a pure PORO — no Rails, no DB.
#
# Mirrors the Swift `Money` struct in `ios/MoneyLover/Core/Money.swift`:
#   - `minor_units` is the amount in the currency's smallest unit
#     (đồng for VND, cents for USD/SGD).
#   - arithmetic is exact integer; add/subtract require the same currency and
#     raise rather than silently coercing.
#
# Rounding rule (see `.from_major` / `#convert`): **round half away from zero**.
# This mirrors Swift's `Money(major:currency:)`, which rounds via
# `NSDecimalNumber.rounding(accordingToBehavior: nil)` → `NSRoundPlain`
# (round half away from zero). The Swift test `MoneyTests.majorInitRoundsToMinorGrid`
# pins this with `(.usd, "1.005", 101)` — 100.5 minor units rounds up to 101.
class Money
  include Comparable

  attr_reader :minor_units, :currency

  # @param minor_units [Integer] exact amount in the currency's smallest unit
  # @param currency    [Symbol, String] e.g. :VND, :USD, :SGD
  def initialize(minor_units:, currency:)
    unless minor_units.is_a?(Integer)
      raise MoneyError::InexactValue,
            "minor_units must be an Integer, got #{minor_units.class}: #{minor_units.inspect}"
    end

    @minor_units = minor_units
    @currency = Currency.normalize(currency)
    freeze
  end

  # Zero in the given currency.
  def self.zero(currency)
    new(minor_units: 0, currency: currency)
  end

  # Builds money from a major-unit amount (e.g. 40000 VND, "1.50" USD),
  # rounding to the currency's minor-unit grid with half-away-from-zero.
  #
  # Accepts Integer, Rational, BigDecimal, or a numeric String — never Float,
  # which is rejected to keep money math exact (mirrors Swift's Decimal-based init).
  def self.from_major(amount, currency)
    target = Currency.normalize(currency)
    scaled = exact(amount) * Currency.minor_unit_scale(target)
    new(minor_units: round_half_away_from_zero(scaled), currency: target)
  end

  # The major-unit value as an exact Rational, for display/formatting only.
  def amount
    Rational(minor_units, Currency.minor_unit_scale(currency))
  end

  def add(other)
    require_same_currency!(other)
    self.class.new(minor_units: minor_units + other.minor_units, currency: currency)
  end
  alias + add

  def subtract(other)
    require_same_currency!(other)
    self.class.new(minor_units: minor_units - other.minor_units, currency: currency)
  end
  alias - subtract

  def negate
    self.class.new(minor_units: -minor_units, currency: currency)
  end
  alias -@ negate

  def zero?
    minor_units.zero?
  end

  def negative?
    minor_units.negative?
  end

  def positive?
    minor_units.positive?
  end

  # Comparable: only meaningful within the same currency. Returns nil for a
  # different currency (so `<`/`>` raise ArgumentError) or a non-Money.
  def <=>(other)
    return nil unless other.is_a?(Money) && other.currency == currency

    minor_units <=> other.minor_units
  end

  def ==(other)
    other.is_a?(Money) && other.currency == currency && other.minor_units == minor_units
  end
  alias eql? ==

  def hash
    [ minor_units, currency ].hash
  end

  # Sums a collection of `Money`, raising on any currency mismatch.
  #
  # Pass `currency:` to fix the result currency — required for an empty
  # collection, and it validates every element matches.
  def self.sum(monies, currency: nil)
    list = monies.to_a

    if currency.nil?
      if list.empty?
        raise ArgumentError, "cannot sum an empty collection without a currency:"
      end

      list.reduce { |acc, money| acc.add(money) }
    else
      list.reduce(zero(currency)) { |acc, money| acc.add(money) }
    end
  end

  # Converts this amount into `to`, multiplying by `rate` (the number of target
  # MAJOR units per one source MAJOR unit) and rounding half away from zero.
  #
  # `rate` mirrors the Swift `Rates.fxRate` shape (e.g. VND per 1 USD): it is an
  # exact value (Integer/Rational/BigDecimal/numeric String), never a Float.
  # Used later by Valuator and TransferFxMath.
  def convert(to:, rate:)
    target_major = amount * self.class.exact(rate)
    self.class.from_major(target_major, to)
  end

  # Coerces an exact numeric into a Rational, rejecting Float (and anything
  # else lossy). This is the single gate that keeps Float out of money math.
  def self.exact(value)
    case value
    when Integer, Rational
      Rational(value)
    when BigDecimal
      value.to_r
    when String
      Rational(value) # parses decimal strings (e.g. "1.005") exactly
    when Float
      raise MoneyError::InexactValue,
            "Float #{value.inspect} is forbidden in money math; use Integer/Rational/BigDecimal/String"
    else
      raise MoneyError::InexactValue, "cannot build exact value from #{value.class}: #{value.inspect}"
    end
  end

  # Rounds an exact Rational to the nearest Integer, ties going away from zero.
  # Mirrors Swift's NSRoundPlain (see class-level rounding note).
  def self.round_half_away_from_zero(rational)
    rational = Rational(rational) unless rational.is_a?(Rational)
    if rational.negative?
      (rational - Rational(1, 2)).ceil
    else
      (rational + Rational(1, 2)).floor
    end
  end

  private

  def require_same_currency!(other)
    return if currency == other.currency

    raise MoneyError::CurrencyMismatch.new(currency, other.currency)
  end
end

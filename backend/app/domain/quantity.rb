# frozen_string_literal: true

require "bigdecimal"

# An exact holding quantity (e.g. 5 chỉ of gold, 500 shares).
#
# Quantity is a SEPARATE exact type from `Money`: a holding's value is
# `quantity × market price`, and the multiplication must stay exact, so the
# quantity is backed by a `Rational` — never a Float (ADR-0015). This mirrors
# the Swift `HoldingInfo.quantity: Decimal` (an exact decimal) in
# `ios/MoneyLover/Core/HoldingInfo.swift`.
class Quantity
  include Comparable

  # The exact magnitude as a Rational.
  attr_reader :value
  # The holding unit (:chi, :luong, :shares).
  attr_reader :unit

  # @param value [Integer, Rational, BigDecimal, String] exact magnitude (no Float)
  # @param unit  [Symbol, String] one of HoldingUnit::ALL
  def initialize(value, unit:)
    @value = self.class.exact(value)
    @unit = HoldingUnit.normalize(unit)
    freeze
  end

  def self.zero(unit:)
    new(0, unit: unit)
  end

  # Equivalent magnitude expressed in chỉ (gold). 1 lượng = 10 chỉ.
  def in_chi
    value * HoldingUnit.chi_per_unit(unit)
  end

  def add(other)
    require_same_unit!(other)
    self.class.new(value + other.value, unit: unit)
  end
  alias + add

  def subtract(other)
    require_same_unit!(other)
    self.class.new(value - other.value, unit: unit)
  end
  alias - subtract

  # Scales the quantity by an exact factor (Integer/Rational/BigDecimal/String).
  def scale(factor)
    self.class.new(value * self.class.exact(factor), unit: unit)
  end

  def zero?
    value.zero?
  end

  def <=>(other)
    return nil unless other.is_a?(Quantity) && other.unit == unit

    value <=> other.value
  end

  def ==(other)
    other.is_a?(Quantity) && other.unit == unit && other.value == value
  end
  alias eql? ==

  def hash
    [ value, unit ].hash
  end

  # Coerces an exact numeric into a Rational, rejecting Float.
  def self.exact(value)
    case value
    when Integer, Rational
      Rational(value)
    when BigDecimal
      value.to_r
    when String
      Rational(value)
    when Float
      raise MoneyError::InexactValue,
            "Float #{value.inspect} is forbidden in quantity math; use Integer/Rational/BigDecimal/String"
    else
      raise MoneyError::InexactValue, "cannot build exact quantity from #{value.class}: #{value.inspect}"
    end
  end

  private

  def require_same_unit!(other)
    return if unit == other.unit

    raise ArgumentError, "cannot combine quantity in #{unit} with quantity in #{other.unit}"
  end
end

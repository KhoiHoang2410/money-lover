# frozen_string_literal: true

# The currencies the app can hold money in. Drives the minor-unit scale and
# fraction-digit count used by `Money`.
#
# Mirrors the Swift `Currency` enum in `ios/MoneyLover/Core/Currency.swift`:
#   VND -> scale 1   (đồng has no minor unit)
#   USD -> scale 100 (cents)
#   SGD -> scale 100 (cents)
#
# A currency is represented in the domain as an upper-case `Symbol`
# (e.g. `:VND`), matching `Money`'s `{ minor_units:, currency: }` shape.
module Currency
  ALL = %i[VND USD SGD].freeze

  # How many minor units make one major unit (1 for VND, 100 for USD/SGD).
  MINOR_UNIT_SCALE = { VND: 1, USD: 100, SGD: 100 }.freeze

  # Number of fraction digits the currency displays (VND has none).
  FRACTION_DIGITS = { VND: 0, USD: 2, SGD: 2 }.freeze

  module_function

  # Coerces `currency` (Symbol or String, any case) into a known currency
  # Symbol, raising on anything we do not support.
  def normalize(currency)
    symbol = currency.to_s.upcase.to_sym
    unless ALL.include?(symbol)
      raise ArgumentError, "unknown currency #{currency.inspect}; expected one of #{ALL.inspect}"
    end

    symbol
  end

  def minor_unit_scale(currency)
    MINOR_UNIT_SCALE.fetch(normalize(currency))
  end

  def fraction_digits(currency)
    FRACTION_DIGITS.fetch(normalize(currency))
  end
end

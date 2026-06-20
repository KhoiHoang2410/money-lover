# frozen_string_literal: true

# Pure math for transfers between the owner's own sources, including the Fee of a
# cross-currency Transfer. No Float, no DB.
#
# Mirrors the Swift `TransferEngine` (`ios/MoneyLover/Core/TransferEngine.swift`)
# and the cross-currency balance moves exercised by `TransferEngineTests`.
#
# Fee (in the destination currency):
#   fee = (amount_out × rate) − amount_in
# where `rate` is destination major units per one source major unit. A positive
# fee is value lost to spread; a favourable rate yields a negative fee. The
# subtraction is done in exact major units and rounded to the destination's
# minor-unit grid exactly once, half away from zero (parity with `fx_fees.json`).
module TransferFxMath
  module_function

  # The Fee of a cross-currency Transfer, expressed in the destination currency.
  #
  # @param amount_out [Money] what leaves the source, in the source currency
  # @param amount_in  [Money] what lands in the destination, in its currency
  # @param rate       [Integer, Rational, BigDecimal, String] dest-per-source major rate (no Float)
  # @return [Money] the fee in the destination currency
  def fee(amount_out:, amount_in:, rate:)
    expected_major = amount_out.amount * Money.exact(rate)
    Money.from_major(expected_major - amount_in.amount, amount_in.currency)
  end

  # Applies a Transfer to the two balances: the source loses `amount_out`, and
  # the destination gains `amount_in` (its native received amount). For a
  # same-currency Transfer `amount_in` may be omitted and defaults to the
  # outgoing amount.
  #
  # The native amounts move whole — this creates/destroys no value beyond the
  # Fee, which is observed separately via {fee}.
  #
  # @return [Hash{Symbol=>Money}] { source_balance:, destination_balance: }
  def apply(source_balance:, destination_balance:, amount_out:, amount_in: nil)
    received = amount_in || amount_out
    {
      source_balance: source_balance.subtract(amount_out),
      destination_balance: destination_balance.add(received)
    }
  end
end

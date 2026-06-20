# frozen_string_literal: true

# Errors raised by the pure-domain money types.
#
# Mirrors the Swift `MoneyError` enum in
# `ios/MoneyLover/Core/MoneyError.swift` so the backend speaks the same
# vocabulary as the iOS `Core` (ADR-0015).
module MoneyError
  # Raised when two `Money` values of different currencies are combined.
  # We never silently coerce currencies — the caller must convert explicitly
  # via `Money#convert`.
  class CurrencyMismatch < StandardError
    attr_reader :left, :right

    def initialize(left, right)
      @left = left
      @right = right
      super("cannot combine money in #{left} with money in #{right}")
    end
  end

  # Raised when a Float (or other inexact value) is offered to money math.
  # Money is integer minor units end to end — floats never enter (ADR-0015).
  class InexactValue < StandardError; end
end

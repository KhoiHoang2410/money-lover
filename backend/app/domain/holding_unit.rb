# frozen_string_literal: true

# The unit a holding's quantity is measured in (gold and stock).
#
# Mirrors the Swift `HoldingUnit` enum in `ios/MoneyLover/Core/HoldingUnit.swift`:
#   :chi    -> 1 chỉ of gold
#   :luong  -> 1 lượng = 10 chỉ
#   :shares -> stock shares
#
# The lượng→chỉ factor (10) is exact and lives here so quantity math (e.g. the
# Valuator pricing gold per chỉ) never re-derives it. The factor is integer,
# never Float.
module HoldingUnit
  ALL = %i[chi luong shares].freeze

  # How many chỉ one unit represents (only meaningful for gold). 1 lượng = 10 chỉ.
  CHI_PER_UNIT = { chi: 1, luong: 10, shares: 1 }.freeze

  LABELS = { chi: "chỉ", luong: "lượng", shares: "shares" }.freeze

  module_function

  def normalize(unit)
    symbol = unit.to_s.downcase.to_sym
    unless ALL.include?(symbol)
      raise ArgumentError, "unknown holding unit #{unit.inspect}; expected one of #{ALL.inspect}"
    end

    symbol
  end

  # Number of chỉ in one of `unit` (gold). Used by quantity math.
  def chi_per_unit(unit)
    CHI_PER_UNIT.fetch(normalize(unit))
  end

  def label(unit)
    LABELS.fetch(normalize(unit))
  end
end

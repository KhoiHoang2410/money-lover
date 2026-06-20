require "bigdecimal"

# A global, all-Users market rate cached by the fetch jobs (CONTEXT.md "Rate").
#
# `key` namespaces the price kind so one table holds every rate the Valuator
# needs (issue 08):
#   fx.<CUR>        VND per 1 major unit of a foreign currency (fx.USD, fx.SGD)
#   gold            VND per chỉ of SJC gold
#   stock.<TICKER>  VND per share of a HOSE stock
#
# `value` is an exact BigDecimal in VND — never a Float (ADR-0015) — so it flows
# straight into Money / Rates math. `stale` is set when the latest fetch failed
# and we keep serving the last good value.
class Rate < ApplicationRecord
  FX_PREFIX = "fx."
  STOCK_PREFIX = "stock."
  GOLD_KEY = "gold"

  # FX keys are limited to the supported foreign currencies (VND is the base, so
  # it is never an fx.* rate). This keeps every fx.* key safe to feed through
  # Currency.normalize when building a Rates snapshot.
  FX_CURRENCIES = (Currency::ALL - [ :VND ]).map(&:to_s).freeze

  # The shapes a rate key may take. Guards both the override API and the fetch
  # jobs against garbage keys (and against unsupported FX currencies).
  KEY_PATTERN = %r{\A(?:fx\.(?:#{FX_CURRENCIES.join('|')})|gold|stock\.[A-Z0-9]{1,10})\z}

  validates :key, presence: true, uniqueness: true, format: { with: KEY_PATTERN }
  validates :value, presence: true

  def self.valid_key?(key)
    KEY_PATTERN.match?(key.to_s)
  end

  # Canonical decimal string for the JSON API: plain (non-scientific) notation
  # with insignificant trailing zeros trimmed. Keeps the wire value exact and
  # stable regardless of the column's stored scale.
  def self.canonical_value(value)
    decimal = value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
    string = decimal.to_s("F")
    string = string.sub(/(\.\d*?)0+\z/, '\1').sub(/\.\z/, "")
    string
  end
end

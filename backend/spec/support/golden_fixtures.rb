# frozen_string_literal: true

require "json"

# Shared helpers for loading the language-neutral golden fixtures (issue 03,
# ADR-0015) and rebuilding the domain value objects each engine case needs.
# The fixtures live at repo-root `golden/fixtures/` and are the parity oracle:
# every engine must reproduce `expected_outputs` exactly.
module GoldenFixtures
  GOLDEN_DIR = File.expand_path("../../../golden/fixtures", __dir__).freeze

  module_function

  # The parsed fixture document for an engine (e.g. "valuation").
  def load(engine)
    JSON.parse(File.read(File.join(GOLDEN_DIR, "#{engine}.json")))
  end

  # Builds a `Money` from a fixture money node ({ "minor_units", "currency" }).
  def money(node)
    MoneyMapping.load(minor_units: node["minor_units"], currency: node["currency"])
  end

  # Builds a `Rates` from a fixture rates node.
  def rates(node)
    Rates.new(
      fx: node["fx"] || {},
      gold_per_chi: node["gold_per_chi"] || 0,
      stock: node["stock"] || {}
    )
  end

  # Builds a `Holding` from a fixture holding node, or nil when absent.
  def holding(node)
    return nil if node.nil?

    Holding.new(
      quantity: Quantity.new(node["quantity"], unit: node["unit"]),
      ticker: node["ticker"]
    )
  end

  # Builds an `Invest` from a fixture transaction node.
  def invest(node)
    Invest.new(
      kind: node["kind"],
      direction: node["trade_direction"],
      quantity: node["trade_quantity"],
      source_id: node["source_id"],
      destination_id: node["destination_id"]
    )
  end
end

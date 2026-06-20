# frozen_string_literal: true

require "rails_helper"
require "json"

# Parity oracle: drives `BudgetEngine` against the language-neutral golden
# fixtures extracted from the Swift Core suite (issue 03 / ADR-0015). Every
# `expected_output` must reproduce byte-identically — including the
# overspent-Envelope case that deducts from the Reserve.
RSpec.describe BudgetEngine, "golden fixtures" do
  BUDGETS_GOLDEN_PATH = File.expand_path("../../../golden/fixtures/budgets.json", __dir__).freeze

  def money(node)
    Money.new(minor_units: node.fetch("minor_units"), currency: node.fetch("currency"))
  end

  def build_envelope(node)
    BudgetEngine::Envelope.build(
      id: node.fetch("id"),
      name: node["name"],
      allocation: money(node.fetch("allocation")),
      carried: node["carried"] && money(node.fetch("carried")),
      is_reserve: node.fetch("is_reserve", false)
    )
  end

  def build_transactions(rows)
    rows.map do |row|
      BudgetEngine::Transaction.build(
        kind: row.fetch("kind"),
        amount: money(row.fetch("amount")),
        source_id: row["source_id"],
        envelope_id: row["envelope_id"]
      )
    end
  end

  doc = JSON.parse(File.read(BUDGETS_GOLDEN_PATH))

  doc.fetch("cases").each do |kase|
    it "reproduces #{kase['name']}" do
      inputs = kase.fetch("inputs")
      expected = kase.fetch("expected_outputs")

      case kase.fetch("method")
      when "spent"
        result = described_class.spent(
          envelope_id: inputs.fetch("envelope_id"),
          transactions: build_transactions(inputs.fetch("transactions")),
          currency: expected.fetch("spent").fetch("currency")
        )
        expect(result).to eq(money(expected.fetch("spent")))

      when "remaining"
        result = described_class.remaining(
          envelope: build_envelope(inputs.fetch("envelope")),
          transactions: build_transactions(inputs.fetch("transactions"))
        )
        expect(result).to eq(money(expected.fetch("remaining")))

      when "month_end"
        envelopes = inputs.fetch("envelopes").map { |node| build_envelope(node) }
        spent_by_envelope = inputs.fetch("spent_by_envelope").to_h do |row|
          [ row.fetch("envelope_id"), money(row.fetch("spent")) ]
        end

        result = described_class.month_end(envelopes: envelopes, spent_by_envelope: spent_by_envelope)

        expect(result.reserve_delta).to eq(money(expected.fetch("reserve_delta")))
        expect(result.line_count).to eq(expected.fetch("line_count"))
        expect(result.lines.map(&:envelope_id)).to eq(expected.fetch("lines").map { |l| l.fetch("envelope_id") })
        expect(result.lines.map(&:leftover)).to eq(expected.fetch("lines").map { |l| money(l.fetch("leftover")) })

      else
        raise "unknown golden method #{kase['method'].inspect}"
      end
    end
  end
end

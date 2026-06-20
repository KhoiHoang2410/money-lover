# frozen_string_literal: true

require "rails_helper"
require "json"

# ReconcileService (issue 12): real balance − Current balance → a signed
# Adjustment per source (CONTEXT.md "Reconcile" / "Adjustment"). The heart of the
# spec is the **golden-vector** check: every case in the shared
# `golden/fixtures/reconcile.json` (issue 03 / ADR-0015) must reproduce
# byte-identically, proving the Ruby engine is a faithful port of the Swift
# `Core` ReconcileService — a verification, not a re-derivation.
RSpec.describe ReconcileService do
  GOLDEN_RECONCILE = File.expand_path("../../../golden/fixtures/reconcile.json", __dir__).freeze

  def money(node)
    MoneyMapping.load(minor_units: node.fetch("minor_units"), currency: node.fetch("currency"))
  end

  def build_source(node)
    BalanceEngine::Source.build(
      id: node.fetch("id"),
      kind: node.fetch("kind"),
      currency: node.fetch("currency"),
      opening_balance: money(node.fetch("opening_balance"))
    )
  end

  def build_transaction(node)
    BalanceEngine::Transaction.build(
      kind: node.fetch("kind"),
      amount: money(node.fetch("amount")),
      source_id: node["source_id"],
      destination_id: node["destination_id"],
      destination_amount: (money(node["destination_amount"]) if node["destination_amount"]),
      direction: node["direction"]
    )
  end

  def build_transactions(rows)
    (rows || []).map { |row| build_transaction(row) }
  end

  describe "golden fixtures parity (byte-identical with Swift Core)" do
    doc = JSON.parse(File.read(GOLDEN_RECONCILE))

    it "covers the reconcile engine fixture" do
      expect(doc["engine"]).to eq("reconcile")
      expect(doc["cases"]).not_to be_empty
    end

    doc.fetch("cases").each do |kase|
      it "reproduces '#{kase['name']}'" do
        inputs = kase.fetch("inputs")
        expected = kase.fetch("expected_outputs")

        case kase.fetch("method")
        when "adjustment"
          source = build_source(inputs.fetch("source"))
          transactions = build_transactions(inputs["transactions"])

          if expected.key?("error")
            expect(expected.fetch("error")).to eq("currency_mismatch")
            expect do
              described_class.adjustment(
                source: source,
                transactions: transactions,
                real_balance: money(inputs.fetch("real_balance"))
              )
            end.to raise_error(MoneyError::CurrencyMismatch)
            next
          end

          result = described_class.adjustment(
            source: source,
            transactions: transactions,
            real_balance: money(inputs.fetch("real_balance")),
            envelope_id: inputs["envelope_id"],
            note: inputs["note"]
          )

          want = expected.fetch("adjustment")
          if want.nil?
            expect(result).to be_nil
          else
            expect(result.kind).to eq(want.fetch("kind").to_sym)
            expect(result.source_id).to eq(want.fetch("source_id"))
            wanted = money(want.fetch("amount"))
            expect(result.amount.minor_units).to eq(wanted.minor_units)
            expect(result.amount.currency).to eq(wanted.currency)
            expect(result.amount).to eq(wanted)
            expect(result.envelope_id).to eq(want["envelope_id"]) if want.key?("envelope_id")
            expect(result.note).to eq(want["note"]) if want.key?("note")

            # The whole point of the signed delta: folding the Adjustment back
            # through BalanceEngine lands the Current balance exactly on reality.
            if expected.key?("reconciled_balance")
              reconciled = BalanceEngine.balance(
                source: source,
                transactions: transactions + [ described_class.as_transaction(result) ]
              )
              expect(reconciled).to eq(money(expected.fetch("reconciled_balance")))
              expect(reconciled).to eq(money(inputs.fetch("real_balance")))
            end
          end

        when "multi_adjustment"
          sources = inputs.fetch("sources").map { |s| build_source(s) }
          transactions = build_transactions(inputs["transactions"])
          real_balances = inputs.fetch("real_balances").to_h do |row|
            [ row.fetch("source_id"), money(row.fetch("balance")) ]
          end

          result = described_class.reconcile(
            sources: sources,
            transactions: transactions,
            real_balances: real_balances
          )

          got = result.adjustments.map do |adj|
            { "source_id" => adj.source_id, "kind" => adj.kind.to_s,
              "minor_units" => adj.amount.minor_units, "currency" => adj.amount.currency.to_s }
          end
          want = expected.fetch("adjustments").map do |a|
            { "source_id" => a.fetch("source_id"), "kind" => a.fetch("kind"),
              "minor_units" => a.fetch("amount").fetch("minor_units"),
              "currency" => a.fetch("amount").fetch("currency") }
          end
          expect(got).to eq(want)
          expect(result.unchanged_sources).to eq(expected.fetch("unchanged_sources"))

        else
          raise "unknown fixture method: #{kase['method'].inspect}"
        end
      end
    end
  end

  describe "unit: multi-source reconcile produces independent adjustments" do
    let(:sources) do
      [
        BalanceEngine::Source.build(id: "a", kind: :account, currency: :VND,
                                    opening_balance: Money.new(minor_units: 1_000_000, currency: :VND)),
        BalanceEngine::Source.build(id: "b", kind: :account, currency: :VND,
                                    opening_balance: Money.new(minor_units: 2_000_000, currency: :VND))
      ]
    end

    it "adjusts only the drifted source and lists the unchanged one" do
      result = described_class.reconcile(
        sources: sources,
        transactions: [],
        real_balances: {
          "a" => Money.new(minor_units: 1_000_000, currency: :VND),
          "b" => Money.new(minor_units: 2_010_000, currency: :VND)
        }
      )

      expect(result.unchanged_sources).to eq([ "a" ])
      expect(result.adjustments.map(&:source_id)).to eq([ "b" ])
      expect(result.adjustments.first.amount).to eq(Money.new(minor_units: 10_000, currency: :VND))
    end

    it "returns no adjustment when reality equals the Current balance" do
      source = sources.first
      result = described_class.adjustment(
        source: source,
        transactions: [],
        real_balance: source.opening_balance
      )
      expect(result).to be_nil
    end

    it "rejects a real balance in a different currency than the source" do
      source = sources.first
      expect do
        described_class.adjustment(
          source: source,
          transactions: [],
          real_balance: Money.new(minor_units: 400, currency: :USD)
        )
      end.to raise_error(MoneyError::CurrencyMismatch)
    end
  end
end

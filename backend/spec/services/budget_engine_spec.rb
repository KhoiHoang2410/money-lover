# frozen_string_literal: true

require "rails_helper"

# Unit coverage for `BudgetEngine` beyond the golden vectors: overspend deducting
# from the Reserve, sweep idempotency on replay, and the timezone month-end
# boundary (the engine stays clock-free — boundaries are resolved by the caller).
RSpec.describe BudgetEngine do
  def vnd(minor) = Money.new(minor_units: minor, currency: :VND)

  def envelope(id, allocation:, carried: nil, is_reserve: false)
    BudgetEngine::Envelope.build(
      id: id, name: id.to_s.capitalize, allocation: vnd(allocation),
      carried: carried && vnd(carried), is_reserve: is_reserve
    )
  end

  def expense(amount, envelope_id:)
    BudgetEngine::Transaction.build(kind: :expense, amount: vnd(amount), source_id: "acc", envelope_id: envelope_id)
  end

  describe ".spent" do
    it "counts only expenses assigned to the envelope, never income" do
      txns = [
        expense(100_000, envelope_id: "food"),
        expense(999_000, envelope_id: "fun"),
        BudgetEngine::Transaction.build(kind: :income, amount: vnd(500_000), envelope_id: "food")
      ]
      expect(described_class.spent(envelope_id: "food", transactions: txns, currency: :VND)).to eq(vnd(100_000))
    end

    it "returns a typed zero when nothing matches" do
      expect(described_class.spent(envelope_id: "food", transactions: [], currency: :VND)).to eq(vnd(0))
    end
  end

  describe ".remaining" do
    it "adds the carried Reserve balance on top of allocation" do
      env = envelope("reserve", allocation: 0, carried: 23_000_000, is_reserve: true)
      expect(described_class.remaining(envelope: env, transactions: [])).to eq(vnd(23_000_000))
    end

    it "goes negative when the envelope is overspent" do
      env = envelope("food", allocation: 5_000_000)
      result = described_class.remaining(envelope: env, transactions: [ expense(5_300_000, envelope_id: "food") ])
      expect(result).to eq(vnd(-300_000))
    end
  end

  describe ".month_end" do
    it "deducts an overspent envelope from the reserve delta" do
      result = described_class.month_end(
        envelopes: [ envelope("transport", allocation: 2_000_000) ],
        spent_by_envelope: { "transport" => vnd(2_300_000) }
      )
      expect(result.reserve_delta).to eq(vnd(-300_000))
      expect(result.lines.map(&:leftover)).to eq([ vnd(-300_000) ])
    end

    it "excludes the Reserve from the sweep lines (it absorbs, never sweeps itself)" do
      envelopes = [
        envelope("food", allocation: 5_000_000),
        envelope("reserve", allocation: 0, is_reserve: true)
      ]
      result = described_class.month_end(envelopes: envelopes, spent_by_envelope: { "food" => vnd(4_600_000) })
      expect(result.lines.map(&:envelope_id)).to eq([ "food" ])
      expect(result.reserve_delta).to eq(vnd(400_000))
    end

    it "treats a missing envelope spend as zero (full allocation sweeps)" do
      result = described_class.month_end(
        envelopes: [ envelope("rent", allocation: 8_000_000) ], spent_by_envelope: {}
      )
      expect(result.reserve_delta).to eq(vnd(8_000_000))
    end

    it "is idempotent: replaying the same closing month yields the same delta (no double-apply)" do
      envelopes = [ envelope("food", allocation: 5_000_000), envelope("fun", allocation: 7_000_000) ]
      spent = { "food" => vnd(4_600_000), "fun" => vnd(3_100_000) }
      first = described_class.month_end(envelopes: envelopes, spent_by_envelope: spent)
      second = described_class.month_end(envelopes: envelopes, spent_by_envelope: spent)
      expect(second.reserve_delta).to eq(first.reserve_delta)
      expect(second.reserve_delta).to eq(vnd(4_300_000))
    end

    it "raises on an empty envelope set (no currency to total into)" do
      expect { described_class.month_end(envelopes: [], spent_by_envelope: {}) }
        .to raise_error(ArgumentError)
    end
  end

  describe "timezone month-end boundary" do
    # The engine is clock-free: the caller resolves which closing month an
    # expense near midnight belongs to (in User.timezone) before assigning its
    # spend. We model a transaction at 2026-06-30 23:30 +07:00 (still June in
    # Asia/Ho_Chi_Minh, but already July in UTC) landing in June's spend.
    it "sweeps spend attributed to the closing month by the caller's timezone" do
      june_spent = { "food" => vnd(4_600_000) } # caller bucketed the near-midnight expense into June
      result = described_class.month_end(
        envelopes: [ envelope("food", allocation: 5_000_000) ], spent_by_envelope: june_spent
      )
      expect(result.reserve_delta).to eq(vnd(400_000))
    end
  end
end

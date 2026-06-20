# frozen_string_literal: true

require "rails_helper"
require "date"

# Golden-vector spec for the pure SignalEngine (issue 20). Mirrors the Swift
# `SignalEngineTests` over known states so the backend Signals match the clients'
# byte-for-byte rules (deterministic integer thresholds, ADR-0004 paused).
RSpec.describe SignalEngine do
  def vnd(minor) = Money.new(minor_units: minor, currency: :VND)

  # 15 June 2026 — mid-month, June has 30 days (elapsed = 15/30).
  let(:as_of) { Date.new(2026, 6, 15) }

  def envelope(name, allocation:, carried: 0, is_reserve: false, id: name)
    SignalEngine::Envelope.new(
      id: id, name: name, allocation: vnd(allocation), carried: vnd(carried), is_reserve: is_reserve
    )
  end

  def expense(amount, envelope_id: nil, day: 10, note: "", id: object_id)
    SignalEngine::Transaction.new(
      id: id, kind: :expense, amount: vnd(amount), envelope_id: envelope_id,
      date: Date.new(2026, 6, day), note: note
    )
  end

  def signals(envelopes: [], transactions: [], goals: [])
    described_class.signals(envelopes: envelopes, transactions: transactions, goals: goals, as_of: as_of)
  end

  describe "envelope pace / overspend" do
    it "fires projectedOverspend (warning) when spending outpaces the elapsed month" do
      food = envelope("Food", allocation: 1_000_000)
      # 600k by day 15/30: 600k·30 = 18M > 1M·15 = 15M → projected to overrun.
      result = signals(envelopes: [ food ], transactions: [ expense(600_000, envelope_id: "Food") ])
      expect(result.size).to eq(1)
      expect(result[0].kind).to eq(:projectedOverspend)
      expect(result[0].severity).to eq(:warning)
      expect(result[0].id).to eq("projectedOverspend-Food")
    end

    it "stays silent when on pace" do
      food = envelope("Food", allocation: 1_000_000)
      # 400k by day 15/30: 400k·30 = 12M < 15M → on pace.
      expect(signals(envelopes: [ food ], transactions: [ expense(400_000, envelope_id: "Food") ])).to be_empty
    end

    it "fires envelopeOverspent (critical) with the exact overage" do
      food = envelope("Food", allocation: 1_000_000)
      result = signals(envelopes: [ food ], transactions: [ expense(1_200_000, envelope_id: "Food") ])
      expect(result.size).to eq(1)
      expect(result[0].kind).to eq(:envelopeOverspent)
      expect(result[0].severity).to eq(:critical)
      expect(result[0].detail).to include("₫200,000")
    end

    it "ignores an Envelope with no Allocation" do
      food = envelope("Food", allocation: 0)
      expect(signals(envelopes: [ food ], transactions: [ expense(50_000, envelope_id: "Food") ])).to be_empty
    end
  end

  # Drives the EXACT pace rule across Feb (28d), Apr (30d), May (31d): the
  # projectedOverspend warning fires iff spent·days_in_month > allocation·day.
  describe "pace threshold (table-driven)" do
    [
      { month: 2, day: 14, allocation: 2_800_000, spent: 1_400_001, fire: true },
      { month: 2, day: 14, allocation: 2_800_000, spent: 1_400_000, fire: false },
      { month: 2, day: 7,  allocation: 2_800_000, spent: 700_001,   fire: true },
      { month: 4, day: 10, allocation: 3_000_000, spent: 1_000_001, fire: true },
      { month: 4, day: 10, allocation: 3_000_000, spent: 1_000_000, fire: false },
      { month: 4, day: 20, allocation: 3_000_000, spent: 1_900_000, fire: false },
      { month: 5, day: 15, allocation: 3_100_000, spent: 1_500_001, fire: true },
      { month: 5, day: 15, allocation: 3_100_000, spent: 1_500_000, fire: false },
      { month: 5, day: 30, allocation: 3_100_000, spent: 3_000_000, fire: false }
    ].each do |c|
      it "month #{c[:month]} day #{c[:day]} spent #{c[:spent]} → fire=#{c[:fire]}" do
        as_of = Date.new(2026, c[:month], c[:day])
        food = SignalEngine::Envelope.new(
          id: "Food", name: "Food", allocation: vnd(c[:allocation]), carried: vnd(0), is_reserve: false
        )
        txn = SignalEngine::Transaction.new(
          id: 1, kind: :expense, amount: vnd(c[:spent]), envelope_id: "Food",
          date: Date.new(2026, c[:month], 1), note: ""
        )
        result = described_class.signals(envelopes: [ food ], transactions: [ txn ], goals: [], as_of: as_of)
        pace = result.find { |s| s.kind == :projectedOverspend }
        if c[:fire]
          expect(pace).not_to be_nil
          expect(pace.severity).to eq(:warning)
          expect(result.any? { |s| s.kind == :envelopeOverspent }).to be(false)
        else
          expect(pace).to be_nil
        end
      end
    end
  end

  describe "goals" do
    def goal(actual:)
      schedule = (1..6).map { |m| Goal::ScheduleLine.new(year: 2026, month: m, amount: vnd(1_000_000)) }
      g = Goal.new(
        id: 7, name: "House", target: vnd(100_000_000),
        start_month: Goal::Month.new(year: 2026, month: 1),
        end_month: Goal::Month.new(year: 2026, month: 6),
        schedule: schedule
      )
      SignalEngine::GoalState.new(goal: g, actual: vnd(actual))
    end

    it "is critical past a 25% shortfall" do
      # expected by June = 6M; actual 3M → 50% behind → critical, 3M short.
      result = signals(goals: [ goal(actual: 3_000_000) ])
      expect(result.size).to eq(1)
      expect(result[0].kind).to eq(:goalBehind)
      expect(result[0].severity).to eq(:critical)
      expect(result[0].detail).to include("₫3,000,000")
    end

    it "is a warning between 10% and 25% behind" do
      # actual 5M of 6M expected → ~17% behind → warning.
      result = signals(goals: [ goal(actual: 5_000_000) ])
      expect(result.size).to eq(1)
      expect(result[0].severity).to eq(:warning)
    end

    it "is silent on plan" do
      expect(signals(goals: [ goal(actual: 6_000_000) ])).to be_empty
    end
  end

  describe "reserve" do
    it "is critical when drained to zero or below" do
      reserve = envelope("Reserve", allocation: 0, carried: 500_000, is_reserve: true)
      result = signals(envelopes: [ reserve ], transactions: [ expense(600_000, envelope_id: "Reserve") ])
      expect(result.size).to eq(1)
      expect(result[0].kind).to eq(:reserveLow)
      expect(result[0].severity).to eq(:critical)
    end

    it "is silent while healthy" do
      reserve = envelope("Reserve", allocation: 0, carried: 500_000, is_reserve: true)
      expect(signals(envelopes: [ reserve ])).to be_empty
    end
  end

  describe "large expense" do
    it "fires above 3× the rest" do
      txs = [ expense(100_000, id: 1), expense(100_000, id: 2), expense(100_000, id: 3),
             expense(1_000_000, note: "Flight", id: 4) ]
      result = signals(transactions: txs)
      expect(result.size).to eq(1)
      expect(result[0].kind).to eq(:largeExpense)
      expect(result[0].detail).to include("Flight")
    end

    it "is silent when spending is even" do
      txs = [ expense(100_000, id: 1), expense(100_000, id: 2), expense(120_000, id: 3) ]
      expect(signals(transactions: txs)).to be_empty
    end

    it "needs at least three Expenses" do
      txs = [ expense(100_000, id: 1), expense(1_000_000, id: 2) ]
      expect(signals(transactions: txs)).to be_empty
    end
  end

  describe "ordering" do
    it "sorts strongest-first (critical … info)" do
      food = envelope("Food", allocation: 1_000_000)
      txs = [
        expense(1_200_000, envelope_id: "Food", id: 1),
        expense(100_000, id: 2), expense(100_000, id: 3), expense(2_000_000, note: "TV", id: 4)
      ]
      result = signals(envelopes: [ food ], transactions: txs)
      expect(result.first.severity).to eq(:critical)
      expect(result.last.severity).to eq(:info)
    end
  end
end

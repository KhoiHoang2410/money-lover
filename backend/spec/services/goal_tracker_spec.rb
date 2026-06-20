# frozen_string_literal: true

require "rails_helper"
require "date"

RSpec.describe GoalTracker do
  def vnd(minor) = Money.new(minor_units: minor, currency: :VND)

  # Jan 100M, Feb 100M, Apr 150M (note the March gap — discontinuous).
  def goal(target: vnd(400_000_000))
    Goal.new(
      name: "House",
      target: target,
      start_month: Goal::Month.new(year: 2026, month: 1),
      end_month: Goal::Month.new(year: 2026, month: 4),
      schedule: [
        Goal::ScheduleLine.new(year: 2026, month: 1, amount: vnd(100_000_000)),
        Goal::ScheduleLine.new(year: 2026, month: 2, amount: vnd(100_000_000)),
        Goal::ScheduleLine.new(year: 2026, month: 4, amount: vnd(150_000_000))
      ]
    )
  end

  tx_class = Struct.new(:kind, :amount, :goal_id, :date, keyword_init: true)
  let(:tx_class) { tx_class }

  describe ".expected_by_today" do
    it "cumulates only lines due through the as-of month" do
      expect(described_class.expected_by_today(goal: goal, as_of: Date.new(2026, 2, 1)))
        .to eq(vnd(200_000_000))
    end

    it "ignores months with no scheduled line (the March gap)" do
      expect(described_class.expected_by_today(goal: goal, as_of: Date.new(2026, 3, 31)))
        .to eq(vnd(200_000_000))
    end

    it "is zero before the funding window opens" do
      expect(described_class.expected_by_today(goal: goal, as_of: Date.new(2025, 12, 31)))
        .to eq(vnd(0))
    end
  end

  describe ".progress" do
    it "is ahead when actual exceeds expected" do
      result = described_class.progress(goal: goal, actual: vnd(250_000_000), as_of: Date.new(2026, 2, 1))
      expect(result.pct_sign).to eq(:positive)
      expect(result.pct).to eq(Rational(1, 4)) # 250/200 - 1
    end

    it "is delayed when actual trails expected" do
      result = described_class.progress(goal: goal, actual: vnd(150_000_000), as_of: Date.new(2026, 2, 1))
      expect(result.pct_sign).to eq(:negative)
    end

    it "has no defined ratio before anything is due" do
      result = described_class.progress(goal: goal, actual: vnd(0), as_of: Date.new(2025, 12, 31))
      expect(result.pct).to be_nil
      expect(result.pct_sign).to eq(:zero)
    end

    it "clamps fraction_of_target to one when over target" do
      result = described_class.progress(goal: goal, actual: vnd(500_000_000), as_of: Date.new(2026, 2, 1))
      expect(result.fraction_of_target).to eq("1")
    end
  end

  describe ".schedule_status" do
    it "marks a past unmet line missed but the current month due" do
      statuses = described_class.schedule_status(
        goal: goal, contributed: vnd(150_000_000), as_of: Date.new(2026, 2, 15)
      )
      expect(statuses).to eq(1 => :funded, 2 => :due, 4 => :pending)
    end

    it "marks an unmet past line missed once its month has passed" do
      statuses = described_class.schedule_status(
        goal: goal, contributed: vnd(100_000_000), as_of: Date.new(2026, 3, 1)
      )
      expect(statuses).to eq(1 => :funded, 2 => :missed, 4 => :pending)
    end
  end

  describe ".shortfalls" do
    it "allocates contributions oldest-first, leaving later lines short" do
      shortfalls = described_class.shortfalls(goal: goal, contributed: vnd(120_000_000))
      expect(shortfalls).to eq(
        1 => vnd(0),
        2 => vnd(80_000_000),
        4 => vnd(150_000_000)
      )
    end
  end

  describe ".contributions" do
    it "returns matching transfers oldest-first and ignores others" do
      txs = [
        tx_class.new(kind: "transfer", amount: vnd(30_000_000), goal_id: "g", date: Date.new(2026, 1, 9)),
        tx_class.new(kind: "transfer", amount: vnd(10_000_000), goal_id: "g", date: Date.new(2026, 1, 2)),
        tx_class.new(kind: "transfer", amount: vnd(99), goal_id: "other", date: Date.new(2026, 1, 1)),
        tx_class.new(kind: "expense", amount: vnd(5), goal_id: nil, date: nil)
      ]
      expect(described_class.contributions(transactions: txs, goal_id: "g").map(&:amount))
        .to eq([ vnd(10_000_000), vnd(30_000_000) ])
    end
  end
end

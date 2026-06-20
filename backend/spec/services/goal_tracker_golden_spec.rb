# frozen_string_literal: true

require "rails_helper"
require "json"
require "date"

# Parity oracle: drives `GoalTracker` against the language-neutral golden
# fixtures extracted from the Swift Core suite (issue 03 / ADR-0015). Every
# `expected_output` must reproduce byte-identically — including the oldest-first
# shortfall allocation and the four Schedule statuses.
RSpec.describe GoalTracker, "golden fixtures" do
  GOLDEN_PATH = File.expand_path("../../../golden/fixtures/goal_tracking.json", __dir__).freeze

  Tx = Struct.new(:kind, :amount, :goal_id, :date, keyword_init: true)

  def money(node)
    Money.new(minor_units: node.fetch("minor_units"), currency: node.fetch("currency"))
  end

  def build_goal(shared)
    schedule = shared.fetch("schedule").map do |line|
      Goal::ScheduleLine.new(
        year: line.fetch("year"),
        month: line.fetch("month"),
        amount: money(line.fetch("amount"))
      )
    end
    start_month = Goal::Month.new(**shared.fetch("start_month").transform_keys(&:to_sym))
    end_month = Goal::Month.new(**shared.fetch("end_month").transform_keys(&:to_sym))

    Goal.new(
      id: shared["name"],
      name: shared.fetch("name"),
      target: money(shared.fetch("target")),
      start_month: start_month,
      end_month: end_month,
      schedule: schedule
    )
  end

  def build_transactions(rows)
    rows.map do |row|
      Tx.new(
        kind: row.fetch("kind"),
        amount: money(row.fetch("amount")),
        goal_id: row["goal_id"],
        date: row["date"] && Date.parse(row["date"])
      )
    end
  end

  doc = JSON.parse(File.read(GOLDEN_PATH))
  shared = doc.fetch("shared")

  doc.fetch("cases").each do |kase|
    it "reproduces #{kase['name']}" do
      inputs = kase.fetch("inputs")
      expected = kase.fetch("expected_outputs")
      goal = inputs["schedule_ref"] ? build_goal(shared.fetch(inputs["schedule_ref"])) : nil

      case kase.fetch("method")
      when "expected_by_today"
        result = described_class.expected_by_today(goal: goal, as_of: Date.parse(inputs.fetch("as_of")))
        expect(result).to eq(money(expected.fetch("expected")))

      when "progress"
        result = described_class.progress(
          goal: goal,
          actual: money(inputs.fetch("actual")),
          as_of: Date.parse(inputs.fetch("as_of"))
        )
        expect(result.expected).to eq(money(expected["expected"])) if expected.key?("expected")
        expect(result.pct_sign).to eq(expected["pct_sign"].to_sym) if expected.key?("pct_sign")
        if expected.key?("fraction_of_target")
          expect(result.fraction_of_target).to eq(expected.fetch("fraction_of_target"))
        end

      when "contributed"
        result = described_class.contributed(
          transactions: build_transactions(inputs.fetch("transactions")),
          goal_id: inputs.fetch("goal_id"),
          currency: expected.fetch("contributed").fetch("currency")
        )
        expect(result).to eq(money(expected.fetch("contributed")))

      when "contributions"
        result = described_class.contributions(
          transactions: build_transactions(inputs.fetch("transactions")),
          goal_id: inputs.fetch("goal_id")
        )
        expect(result.map(&:amount)).to eq(expected.fetch("ordered_amounts").map { |m| money(m) })

      when "schedule_status"
        result = described_class.schedule_status(
          goal: goal,
          contributed: money(inputs.fetch("contributed")),
          as_of: Date.parse(inputs.fetch("as_of"))
        )
        expected.fetch("status_by_month").each do |month, status|
          expect(result[month.to_i]).to eq(status.to_sym),
                                         "month #{month}: expected #{status}, got #{result[month.to_i]}"
        end

      when "shortfalls"
        result = described_class.shortfalls(
          goal: goal,
          contributed: money(inputs.fetch("contributed"))
        )
        expected.fetch("shortfall_by_month").each do |month, amount|
          expect(result[month.to_i]).to eq(money(amount)),
                                         "month #{month}: expected #{amount}, got #{result[month.to_i]&.minor_units}"
        end

      else
        raise "unknown golden method #{kase['method'].inspect}"
      end
    end
  end
end

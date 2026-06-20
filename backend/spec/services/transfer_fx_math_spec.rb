# frozen_string_literal: true

require "rails_helper"

# Drives TransferFxMath against the shared golden `fx_fees.json` fixture (Fee
# computation and native-amount balance moves), plus unit cases pinning the
# rounding boundary and the destination currency (ADR-0015 parity oracle).
RSpec.describe TransferFxMath do
  describe "golden fixtures (fx_fees.json)" do
    doc = GoldenFixtures.load("fx_fees")

    doc["cases"].each do |c|
      it "reproduces #{c['name']} byte-identically" do
        inputs = c["inputs"]
        expected = c["expected_outputs"]

        case c["method"]
        when "fee"
          fee = described_class.fee(
            amount_out: GoldenFixtures.money(inputs["amount_out"]),
            amount_in: GoldenFixtures.money(inputs["amount_in"]),
            rate: inputs["rate"]
          )
          expect(fee).to eq(GoldenFixtures.money(expected["fee"]))

        when "transfer_balances"
          source = inputs["source"]
          destination = inputs["destination"]
          txn = inputs["transaction"]
          dest_amount = txn["destination_amount"] ? GoldenFixtures.money(txn["destination_amount"]) : nil

          result = described_class.apply(
            source_balance: GoldenFixtures.money(source["opening_balance"]),
            destination_balance: GoldenFixtures.money(destination["opening_balance"]),
            amount_out: GoldenFixtures.money(txn["amount"]),
            amount_in: dest_amount
          )

          expect(result[:source_balance]).to eq(GoldenFixtures.money(expected["source_balance"]))
          expect(result[:destination_balance]).to eq(GoldenFixtures.money(expected["destination_balance"]))

        else
          raise "unknown method #{c['method'].inspect}"
        end
      end
    end

    it "covers every fixture case" do
      expect(doc["cases"].size).to eq(5)
    end
  end

  describe "#fee" do
    it "is the expected-minus-received spread, in the destination currency" do
      fee = described_class.fee(
        amount_out: Money.new(minor_units: 60_000, currency: :SGD),
        amount_in: Money.new(minor_units: 10_950_000, currency: :VND),
        rate: 18_500
      )
      expect(fee).to eq(Money.new(minor_units: 150_000, currency: :VND))
    end

    it "is zero when the rate exactly matches the received amount" do
      fee = described_class.fee(
        amount_out: Money.new(minor_units: 100, currency: :USD),
        amount_in: Money.new(minor_units: 25_500, currency: :VND),
        rate: 25_500
      )
      expect(fee).to eq(Money.zero(:VND))
    end

    it "is negative for a favourable rate" do
      fee = described_class.fee(
        amount_out: Money.new(minor_units: 10_000, currency: :SGD),
        amount_in: Money.new(minor_units: 1_900_000, currency: :VND),
        rate: 18_500
      )
      expect(fee).to eq(Money.new(minor_units: -50_000, currency: :VND))
    end

    it "rounds once at the destination grid, half away from zero" do
      # 1.005 USD-major spread on a USD destination -> 100.5 minor -> 101.
      fee = described_class.fee(
        amount_out: Money.new(minor_units: 100, currency: :USD),
        amount_in: Money.new(minor_units: 0, currency: :USD),
        rate: "1.005"
      )
      expect(fee).to eq(Money.new(minor_units: 101, currency: :USD))
    end

    it "rejects a Float rate (no float in money math)" do
      expect {
        described_class.fee(
          amount_out: Money.new(minor_units: 100, currency: :USD),
          amount_in: Money.zero(:VND),
          rate: 25_500.0
        )
      }.to raise_error(MoneyError::InexactValue)
    end
  end

  describe "#apply" do
    it "moves native amounts whole across currencies" do
      result = described_class.apply(
        source_balance: Money.new(minor_units: 240_000, currency: :SGD),
        destination_balance: Money.new(minor_units: 12_500_000, currency: :VND),
        amount_out: Money.new(minor_units: 60_000, currency: :SGD),
        amount_in: Money.new(minor_units: 10_950_000, currency: :VND)
      )
      expect(result[:source_balance]).to eq(Money.new(minor_units: 180_000, currency: :SGD))
      expect(result[:destination_balance]).to eq(Money.new(minor_units: 23_450_000, currency: :VND))
    end

    it "defaults the received amount to the outgoing amount for same-currency transfers" do
      result = described_class.apply(
        source_balance: Money.new(minor_units: 80_000_000, currency: :VND),
        destination_balance: Money.new(minor_units: -18_300_000, currency: :VND),
        amount_out: Money.new(minor_units: 18_300_000, currency: :VND)
      )
      expect(result[:source_balance]).to eq(Money.new(minor_units: 61_700_000, currency: :VND))
      expect(result[:destination_balance]).to eq(Money.zero(:VND))
    end
  end
end

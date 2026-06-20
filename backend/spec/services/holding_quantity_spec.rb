# frozen_string_literal: true

require "rails_helper"

# Drives HoldingQuantity against the shared golden `holding_quantity.json`
# fixture (live-quantity vectors and the oversell guard), plus unit cases that
# pin exact fractional math and the blocked-sell error (ADR-0010 parity).
RSpec.describe HoldingQuantity do
  describe "golden fixtures (holding_quantity.json)" do
    doc = GoldenFixtures.load("holding_quantity")

    doc["cases"].each do |c|
      it "reproduces #{c['name']} byte-identically" do
        inputs = c["inputs"]
        holding = inputs["holding"]
        holding_id = holding["id"]
        opening = holding["holding"]["quantity"]
        expected = c["expected_outputs"]

        case c["method"]
        when "live_quantity"
          trades = inputs["transactions"].map { |t| GoldenFixtures.invest(t) }
          live = described_class.live_quantity(
            opening: opening, holding_id: holding_id, transactions: trades
          )
          expect(live).to eq(Quantity.exact(expected["live_quantity"]))

        when "sell_guard"
          priors = inputs["prior_transactions"].map { |t| GoldenFixtures.invest(t) }
          live = described_class.live_quantity(
            opening: opening, holding_id: holding_id, transactions: priors
          )
          attempted = inputs["attempted_sell_quantity"]

          expect(live).to eq(Quantity.exact(expected["live_quantity"]))

          allowed = described_class.sell_allowed?(live_quantity: live, sell_quantity: attempted)
          expect(allowed).to eq(expected["sell_allowed"])

          if expected["sell_allowed"]
            resulting = described_class.apply_sell(live_quantity: live, sell_quantity: attempted)
            expect(resulting).to eq(Quantity.exact(expected["resulting_quantity"]))
          else
            expect {
              described_class.apply_sell(live_quantity: live, sell_quantity: attempted)
            }.to raise_error(HoldingQuantity::OversellError)
          end

        else
          raise "unknown method #{c['method'].inspect}"
        end
      end
    end

    it "covers every fixture case" do
      expect(doc["cases"].size).to eq(9)
    end
  end

  describe "unit behaviour" do
    let(:gold_id) { "gold" }

    def buy(quantity, holding: gold_id)
      Invest.new(direction: :buy, quantity: quantity, destination_id: holding)
    end

    def sell(quantity, holding: gold_id)
      Invest.new(direction: :sell, quantity: quantity, destination_id: holding)
    end

    it "nets buys and sells exactly from a zero opening" do
      live = described_class.live_quantity(
        opening: "0", holding_id: gold_id,
        transactions: [ buy("5"), sell("2"), buy("1") ]
      )
      expect(live).to eq(Rational(4))
    end

    it "keeps fractional quantities exact (no float drift)" do
      live = described_class.live_quantity(
        opening: "0.5", holding_id: gold_id, transactions: [ buy("0.25") ]
      )
      expect(live).to eq(Rational(3, 4))
    end

    it "ignores trades for other holdings" do
      live = described_class.live_quantity(
        opening: "3", holding_id: gold_id,
        transactions: [ buy("10", holding: "other") ]
      )
      expect(live).to eq(Rational(3))
    end

    it "allows a sell up to the live quantity" do
      expect(described_class.sell_allowed?(live_quantity: "3", sell_quantity: "3")).to be(true)
    end

    it "blocks an oversell" do
      expect(described_class.sell_allowed?(live_quantity: "3", sell_quantity: "5")).to be(false)
    end

    it "raises OversellError when applying an oversell" do
      expect {
        described_class.apply_sell(live_quantity: "3", sell_quantity: "5")
      }.to raise_error(HoldingQuantity::OversellError)
    end

    it "accepts a Quantity opening, using its magnitude" do
      live = described_class.live_quantity(
        opening: Quantity.new("2.5", unit: :chi), holding_id: gold_id, transactions: []
      )
      expect(live).to eq(Rational(5, 2))
    end

    it "rejects a Float quantity (no float in quantity math)" do
      expect { described_class.live_quantity(opening: 0.5, holding_id: gold_id) }
        .to raise_error(MoneyError::InexactValue)
    end
  end
end

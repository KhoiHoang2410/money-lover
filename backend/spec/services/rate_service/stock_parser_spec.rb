require "rails_helper"

RSpec.describe RateService::StockParser do
  let(:body) { File.read(Rails.root.join("spec/fixtures/rates/stock_upstream.json")) }

  it "parses each quote into an exact stock.<TICKER> BigDecimal" do
    result = described_class.parse(body)

    expect(result).to eq(
      "stock.VNM" => BigDecimal("65000"),
      "stock.FPT" => BigDecimal("120500")
    )
    expect(result.values).to all(be_a(BigDecimal))
  end

  it "rejects a Float value" do
    body = { "quotes" => [ { "symbol" => "VNM", "price" => 65_000.0 } ] }
    expect { described_class.parse(body) }.to raise_error(ArgumentError, /Float/)
  end
end

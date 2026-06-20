require "rails_helper"

RSpec.describe RateService::GoldParser do
  let(:body) { File.read(Rails.root.join("spec/fixtures/rates/gold_upstream.json")) }

  it "parses the per-chỉ sell price into an exact gold rate" do
    result = described_class.parse(body)

    expect(result).to eq("gold" => BigDecimal("6950000"))
    expect(result["gold"]).to be_a(BigDecimal)
  end

  it "rejects a Float value" do
    body = { "items" => [ { "unit" => "chi", "sell" => 6_950_000.0 } ] }
    expect { described_class.parse(body) }.to raise_error(ArgumentError, /Float/)
  end
end

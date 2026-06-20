require "rails_helper"

# Parser unit tests run against a captured upstream fixture (no live network),
# proving the conversion to exact integer-safe values (ADR-0015).
RSpec.describe RateService::FxParser do
  let(:body) { File.read(Rails.root.join("spec/fixtures/rates/fx_upstream.json")) }

  it "parses supported currencies into exact fx.<CUR> BigDecimals" do
    result = described_class.parse(body)

    expect(result["fx.USD"]).to eq(BigDecimal("25500"))
    expect(result["fx.SGD"]).to eq(BigDecimal("18750.5"))
    expect(result.values).to all(be_a(BigDecimal))
  end

  it "ignores unsupported currencies (EUR is not a known currency)" do
    expect(described_class.parse(body)).not_to have_key("fx.EUR")
  end

  it "accepts a pre-parsed Hash too" do
    expect(described_class.parse({ "rates" => { "USD" => "25500" } }))
      .to eq("fx.USD" => BigDecimal("25500"))
  end

  it "rejects a Float value (no floats in rate math)" do
    expect { described_class.parse({ "rates" => { "USD" => 25_500.5 } }) }
      .to raise_error(ArgumentError, /Float/)
  end
end

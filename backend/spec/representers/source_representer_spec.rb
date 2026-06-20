require "rails_helper"

# Output-shape contract for SourceRepresenter: money renders as integer minor
# units (MoneyMinorUnits), opening_balance appears only for money sources and the
# holding block only for Holdings.
RSpec.describe SourceRepresenter, type: :representer do
  let(:user) { User.create!(timezone: User::DEFAULT_TIMEZONE) }

  def render(source)
    JSON.parse(described_class.new(SourcePresenter.new(source)).to_json)
  end

  it "renders an account with money as minor units and no holding block" do
    source = user.sources.create!(kind: "account", name: "VPBank",
                                  currency: "VND", opening_minor_units: 1_000_000)

    json = render(source)

    expect(json).to include(
      "id" => source.id, "kind" => "account", "name" => "VPBank", "currency" => "VND",
      "opening_balance" => { "amount_minor" => 1_000_000, "currency" => "VND" },
      "current_balance" => { "amount_minor" => 1_000_000, "currency" => "VND" },
      "valuation" => { "amount_minor" => 1_000_000, "currency" => "VND" }
    )
    expect(json).not_to have_key("holding")
  end

  it "renders a holding with its quantity block and no opening_balance" do
    source = user.sources.create!(kind: "holding", name: "SJC Gold", currency: "VND",
                                  opening_quantity: "1.5", holding_unit: "chi")

    json = render(source)

    expect(json["holding"]).to eq("opening_quantity" => "1.5", "unit" => "chi", "ticker" => nil)
    expect(json).not_to have_key("opening_balance")
    expect(json["current_balance"]).to eq("amount_minor" => 0, "currency" => "VND")
  end

  it "formats whole-number quantities without trailing zeros" do
    source = user.sources.create!(kind: "holding", name: "Shares", currency: "VND",
                                  opening_quantity: "120", holding_unit: "shares", ticker: "VNM")

    expect(render(source)["holding"]["opening_quantity"]).to eq("120")
  end
end

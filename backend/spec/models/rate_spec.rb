require "rails_helper"

RSpec.describe Rate do
  describe "validations" do
    it "accepts the supported key shapes" do
      expect(Rate.new(key: "fx.USD", value: 1)).to be_valid
      expect(Rate.new(key: "gold", value: 1)).to be_valid
      expect(Rate.new(key: "stock.VNM", value: 1)).to be_valid
    end

    it "rejects garbage and unsupported keys" do
      expect(Rate.new(key: "fx.EUR", value: 1)).not_to be_valid
      expect(Rate.new(key: "fx.VND", value: 1)).not_to be_valid
      expect(Rate.new(key: "wat", value: 1)).not_to be_valid
    end

    it "requires a value and a unique key" do
      Rate.create!(key: "gold", value: 1)
      expect(Rate.new(key: "gold", value: 2)).not_to be_valid
      expect(Rate.new(key: "fx.USD")).not_to be_valid
    end
  end

  describe ".canonical_value" do
    it "renders an exact plain decimal string with trailing zeros trimmed" do
      expect(Rate.canonical_value(BigDecimal("25500"))).to eq("25500")
      expect(Rate.canonical_value(BigDecimal("18750.5"))).to eq("18750.5")
      expect(Rate.canonical_value(BigDecimal("1.500"))).to eq("1.5")
      expect(Rate.canonical_value(BigDecimal("6950000.0000000000"))).to eq("6950000")
    end
  end
end

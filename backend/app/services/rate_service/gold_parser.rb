require "json"

module RateService
  # Converts an upstream SJC gold payload into the exact `gold` rate (VND per
  # chỉ — the unit the Valuator prices Holdings in, issue 08). Uses the sell
  # quote. Pure; rejects Float values (ADR-0015).
  module GoldParser
    SOURCE = "sjc"

    module_function

    # @param body [String, Hash] raw JSON body (or pre-parsed Hash)
    # @return [Hash{String=>BigDecimal}] { "gold" => 0.695e7 }
    def parse(body)
      data = body.is_a?(String) ? JSON.parse(body) : body

      items = data.fetch("items")
      item = items.find { |entry| entry["unit"] == "chi" } || items.first

      { Rate::GOLD_KEY => RateService.exact(item.fetch("sell")) }
    end
  end
end

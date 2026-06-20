require "json"

module RateService
  # Converts an upstream HOSE quote payload into exact `stock.<TICKER>` rates
  # (VND per share). Pure; rejects Float values (ADR-0015).
  module StockParser
    SOURCE = "hose"

    module_function

    # @param body [String, Hash] raw JSON body (or pre-parsed Hash)
    # @return [Hash{String=>BigDecimal}] e.g. { "stock.VNM" => 0.65e5 }
    def parse(body)
      data = body.is_a?(String) ? JSON.parse(body) : body

      data.fetch("quotes").each_with_object({}) do |quote, acc|
        key = "stock.#{quote.fetch('symbol').to_s.upcase}"
        next unless Rate.valid_key?(key)

        acc[key] = RateService.exact(quote.fetch("price"))
      end
    end
  end
end

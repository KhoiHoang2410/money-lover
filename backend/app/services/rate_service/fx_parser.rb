require "json"

module RateService
  # Converts an upstream FX payload into exact `fx.<CUR>` rates (VND per 1 major
  # unit). Pure: takes a captured response body, never touches the network.
  # Floats in the payload are rejected (ADR-0015) — upstream must quote strings
  # or integers.
  module FxParser
    SOURCE = "fx"

    module_function

    # @param body [String, Hash] raw JSON body (or pre-parsed Hash)
    # @return [Hash{String=>BigDecimal}] e.g. { "fx.USD" => 0.2505e5 }
    def parse(body)
      data = body.is_a?(String) ? JSON.parse(body) : body

      data.fetch("rates").each_with_object({}) do |(code, raw), acc|
        key = "fx.#{code.to_s.upcase}"
        next unless Rate.valid_key?(key)

        acc[key] = RateService.exact(raw)
      end
    end
  end
end

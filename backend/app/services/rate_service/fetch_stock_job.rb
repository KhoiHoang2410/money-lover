require "net/http"
require "uri"

module RateService
  # Scheduled Sidekiq job: pull HOSE share prices, parse them, and refresh the
  # global `stock.*` cache. Failure flags the cached values stale and returns.
  class FetchStockJob
    include Sidekiq::Job

    SOURCE = "hose"
    KEY_PREFIX = "stock."
    DEFAULT_URL = "https://rates.example.invalid/stocks/hose"

    def perform
      RateService.upsert_globals(StockParser.parse(fetch_body), source: SOURCE)
    rescue StandardError => e
      Rails.logger.warn("[RateService] stock fetch failed: #{e.class}: #{e.message}")
      RateService.mark_stale(KEY_PREFIX)
    end

    private

    def fetch_body
      Net::HTTP.get(URI(ENV.fetch("STOCK_RATES_URL", DEFAULT_URL)))
    end
  end
end

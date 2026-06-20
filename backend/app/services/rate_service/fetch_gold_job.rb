require "net/http"
require "uri"

module RateService
  # Scheduled Sidekiq job: pull the SJC gold price, parse it, and refresh the
  # global `gold` cache. Failure flags the cached value stale and returns.
  class FetchGoldJob
    include Sidekiq::Job

    SOURCE = "sjc"
    KEY_PREFIX = Rate::GOLD_KEY
    DEFAULT_URL = "https://rates.example.invalid/gold/sjc"

    def perform
      RateService.upsert_globals(GoldParser.parse(fetch_body), source: SOURCE)
    rescue StandardError => e
      Rails.logger.warn("[RateService] gold fetch failed: #{e.class}: #{e.message}")
      RateService.mark_stale(KEY_PREFIX)
    end

    private

    def fetch_body
      Net::HTTP.get(URI(ENV.fetch("GOLD_RATES_URL", DEFAULT_URL)))
    end
  end
end

require "net/http"
require "uri"

module RateService
  # Scheduled Sidekiq job: pull the latest FX rates, parse them to exact values,
  # and refresh the global `fx.*` cache. On any failure it flags the cached
  # rates stale and returns — the last good value keeps serving, the job never
  # crashes the queue (CONTEXT.md "Rate": stale fallback).
  class FetchFxJob
    include Sidekiq::Job

    SOURCE = "fx"
    KEY_PREFIX = "fx."
    DEFAULT_URL = "https://rates.example.invalid/fx"

    def perform
      RateService.upsert_globals(FxParser.parse(fetch_body), source: SOURCE)
    rescue StandardError => e
      Rails.logger.warn("[RateService] FX fetch failed: #{e.class}: #{e.message}")
      RateService.mark_stale(KEY_PREFIX)
    end

    private

    def fetch_body
      Net::HTTP.get(URI(ENV.fetch("FX_RATES_URL", DEFAULT_URL)))
    end
  end
end

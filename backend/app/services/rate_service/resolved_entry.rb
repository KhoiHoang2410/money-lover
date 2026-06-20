module RateService
  # One rate as seen by a specific User after override resolution: the override
  # value when present, else the global cached value, carrying the global's
  # provenance (source / fetched_at / stale) so clients can show freshness.
  ResolvedEntry = Struct.new(
    :key, :value, :source, :fetched_at, :stale, :overridden,
    keyword_init: true
  )
end

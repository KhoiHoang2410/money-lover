require "bigdecimal"

# The resolved-rate provider (issue 19) that sits between the cached global
# `Rate` rows / per-User `RateOverride` rows and the pure `Valuator` (issue 08).
#
# Override resolution rule (CONTEXT.md "Rate"): a User's override wins for that
# User only; otherwise the global cached value; the global keeps serving even
# when flagged `stale` (last-good fallback after a failed fetch).
#
# All values are exact BigDecimals in VND — Float never enters rate math
# (ADR-0015), so the produced `Rates` flows straight into `Money`.
module RateService
  module_function

  # Every resolved rate for `user` (global ∪ override keys), ordered by key.
  def resolved_entries(user)
    globals = Rate.order(:key).index_by(&:key)
    overrides = user.rate_overrides.index_by(&:key)

    (globals.keys | overrides.keys).sort.map do |key|
      build_entry(key, globals[key], overrides[key])
    end
  end

  # The single resolved rate for `key`, or nil when neither a global nor an
  # override exists for it.
  def resolved_entry(user, key)
    global = Rate.find_by(key: key)
    override = user.rate_overrides.find_by(key: key)
    return if global.nil? && override.nil?

    build_entry(key, global, override)
  end

  # The `Rates` snapshot the Valuator consumes, resolved for this User.
  def resolved_rates(user)
    fx = {}
    stock = {}
    gold = 0

    resolved_entries(user).each do |entry|
      case entry.key
      when /\Afx\.(.+)\z/ then fx[Regexp.last_match(1)] = entry.value
      when Rate::GOLD_KEY then gold = entry.value
      when /\Astock\.(.+)\z/ then stock[Regexp.last_match(1)] = entry.value
      end
    end

    Rates.new(fx: fx, gold_per_chi: gold, stock: stock)
  end

  # Create/replace `user`'s override for `key`. Raises ApiError::Validation on a
  # bad key or a non-exact/negative value (→ 422).
  def set_override(user, key, raw_value)
    unless Rate.valid_key?(key)
      raise ApiError::Validation.new("Unknown rate key #{key.inspect}.")
    end

    value = parse_override_value(raw_value)
    override = user.rate_overrides.find_or_initialize_by(key: key)
    override.value = value
    override.save!
    override
  end

  # Remove `user`'s override for `key` (idempotent).
  def clear_override(user, key)
    user.rate_overrides.where(key: key).destroy_all
  end

  # Upsert the freshly fetched global rates (key => exact value). Called by the
  # fetch jobs on a successful pull; clears any prior stale flag.
  def upsert_globals(values, source:, now: Time.current)
    values.each do |key, value|
      rate = Rate.find_or_initialize_by(key: key)
      rate.assign_attributes(value: value, source: source, fetched_at: now, stale: false)
      rate.save!
    end
  end

  # Flag every cached rate under `key_prefix` stale after a failed fetch, so the
  # last good value keeps being served rather than disappearing.
  def mark_stale(key_prefix)
    Rate.where("key LIKE ?", "#{sanitize_like(key_prefix)}%")
        .update_all(stale: true, updated_at: Time.current)
  end

  # Coerce an upstream/override scalar into an exact BigDecimal, rejecting Float
  # (the single gate that keeps Float out of rate math, mirroring Money.exact).
  def exact(raw)
    case raw
    when BigDecimal then raw
    when Integer then BigDecimal(raw)
    when String then BigDecimal(raw)
    when Float
      raise ArgumentError, "Float #{raw.inspect} is forbidden in rate math (ADR-0015)"
    else
      raise ArgumentError, "cannot build an exact rate from #{raw.class}: #{raw.inspect}"
    end
  end

  # PRIVATE-ish helpers (module_function exposes them, but they are internal).

  def build_entry(key, global, override)
    if override
      ResolvedEntry.new(
        key: key, value: override.value,
        source: global&.source, fetched_at: global&.fetched_at,
        stale: global ? global.stale : false, overridden: true
      )
    else
      ResolvedEntry.new(
        key: key, value: global.value, source: global.source,
        fetched_at: global.fetched_at, stale: global.stale, overridden: false
      )
    end
  end

  def parse_override_value(raw_value)
    exact(raw_value).tap do |decimal|
      if decimal.negative?
        raise ApiError::Validation.new("Rate value must not be negative.")
      end
    end
  rescue ArgumentError
    raise ApiError::Validation.new(
      "Rate value #{raw_value.inspect} must be an exact, non-negative decimal string."
    )
  end

  def sanitize_like(prefix)
    prefix.to_s.gsub(/[\\%_]/) { |char| "\\#{char}" }
  end
end

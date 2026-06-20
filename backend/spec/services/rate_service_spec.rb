require "rails_helper"

# The resolved-rate provider (issue 19): override wins for one User only, else
# the global cached value, else stale fallback. These are the rules the Valuator
# (issue 08) depends on.
RSpec.describe RateService do
  let(:alice) { User.create!(timezone: "Asia/Ho_Chi_Minh") }
  let(:bob)   { User.create!(timezone: "Asia/Ho_Chi_Minh") }

  def seed_global(key, value, source: "fx", stale: false, fetched_at: Time.utc(2026, 6, 20, 8))
    Rate.create!(key: key, value: value, source: source, stale: stale, fetched_at: fetched_at)
  end

  describe "override resolution" do
    it "serves the global value when the User has no override" do
      seed_global("fx.USD", BigDecimal("25500"))

      entry = RateService.resolved_entry(alice, "fx.USD")

      expect(entry.value).to eq(BigDecimal("25500"))
      expect(entry.overridden).to be(false)
      expect(entry.stale).to be(false)
      expect(entry.source).to eq("fx")
    end

    it "lets the User's override win over the global value" do
      seed_global("fx.USD", BigDecimal("25500"))
      RateService.set_override(alice, "fx.USD", "26000")

      entry = RateService.resolved_entry(alice, "fx.USD")

      expect(entry.value).to eq(BigDecimal("26000"))
      expect(entry.overridden).to be(true)
      # Provenance of the global is still surfaced.
      expect(entry.source).to eq("fx")
    end

    it "isolates an override to the owning User" do
      seed_global("fx.USD", BigDecimal("25500"))
      RateService.set_override(alice, "fx.USD", "26000")

      expect(RateService.resolved_entry(alice, "fx.USD").value).to eq(BigDecimal("26000"))
      expect(RateService.resolved_entry(bob, "fx.USD").value).to eq(BigDecimal("25500"))
      expect(RateService.resolved_entry(bob, "fx.USD").overridden).to be(false)
    end

    it "serves a stale-flagged global as the last-good fallback" do
      seed_global("fx.USD", BigDecimal("25500"), stale: true)

      entry = RateService.resolved_entry(alice, "fx.USD")

      expect(entry.value).to eq(BigDecimal("25500"))
      expect(entry.stale).to be(true)
    end

    it "exposes an override with no global counterpart" do
      RateService.set_override(alice, "stock.VNM", "70000")

      entry = RateService.resolved_entry(alice, "stock.VNM")

      expect(entry.value).to eq(BigDecimal("70000"))
      expect(entry.overridden).to be(true)
      expect(entry.source).to be_nil
      expect(entry.fetched_at).to be_nil
    end
  end

  describe ".resolved_rates (Valuator provider)" do
    it "builds a Rates snapshot the Valuator consumes, with overrides applied" do
      seed_global("fx.USD", BigDecimal("25500"))
      seed_global("gold", BigDecimal("6950000"), source: "sjc")
      seed_global("stock.FPT", BigDecimal("120500"), source: "hose")
      RateService.set_override(alice, "fx.USD", "26000")

      rates = RateService.resolved_rates(alice)

      expect(rates).to be_a(Rates)
      expect(rates.fx_rate(:USD)).to eq(BigDecimal("26000"))
      expect(rates.fx_rate(:VND)).to eq(1)
      expect(rates.gold_per_chi).to eq(BigDecimal("6950000"))
      expect(rates.stock_price("FPT")).to eq(BigDecimal("120500"))

      # And it actually flows through the pure Valuator without losing precision.
      value = Valuator.value_in_vnd(
        kind: :account, currency: :USD,
        balance: Money.new(minor_units: 100, currency: :USD), rates: rates
      )
      expect(value).to eq(Money.new(minor_units: 26_000, currency: :VND))
    end

    it "is the global value for a User without overrides" do
      seed_global("fx.USD", BigDecimal("25500"))
      expect(RateService.resolved_rates(bob).fx_rate(:USD)).to eq(BigDecimal("25500"))
    end
  end

  describe ".set_override validation" do
    it "rejects an unknown key" do
      expect { RateService.set_override(alice, "fx.JPY", "100") }
        .to raise_error(ApiError::Validation)
    end

    it "rejects a non-numeric value" do
      expect { RateService.set_override(alice, "fx.USD", "abc") }
        .to raise_error(ApiError::Validation)
    end

    it "rejects a negative value" do
      expect { RateService.set_override(alice, "fx.USD", "-1") }
        .to raise_error(ApiError::Validation)
    end

    it "rejects a Float value (no floats)" do
      expect { RateService.set_override(alice, "fx.USD", 26_000.5) }
        .to raise_error(ApiError::Validation)
    end

    it "replaces an existing override rather than duplicating it" do
      RateService.set_override(alice, "fx.USD", "26000")
      RateService.set_override(alice, "fx.USD", "27000")

      expect(alice.rate_overrides.where(key: "fx.USD").count).to eq(1)
      expect(RateService.resolved_entry(alice, "fx.USD").value).to eq(BigDecimal("27000"))
    end
  end

  describe ".clear_override" do
    it "removes the override and is idempotent" do
      seed_global("fx.USD", BigDecimal("25500"))
      RateService.set_override(alice, "fx.USD", "26000")

      RateService.clear_override(alice, "fx.USD")
      expect(RateService.resolved_entry(alice, "fx.USD").value).to eq(BigDecimal("25500"))

      expect { RateService.clear_override(alice, "fx.USD") }.not_to raise_error
    end
  end

  describe ".upsert_globals / .mark_stale" do
    it "upserts fresh values and clears the stale flag" do
      seed_global("fx.USD", BigDecimal("25000"), stale: true)

      RateService.upsert_globals({ "fx.USD" => BigDecimal("25500") }, source: "fx")

      rate = Rate.find_by(key: "fx.USD")
      expect(rate.value).to eq(BigDecimal("25500"))
      expect(rate.stale).to be(false)
    end

    it "marks only the matching prefix stale" do
      seed_global("fx.USD", BigDecimal("25500"))
      seed_global("gold", BigDecimal("6950000"), source: "sjc")

      RateService.mark_stale("fx.")

      expect(Rate.find_by(key: "fx.USD").stale).to be(true)
      expect(Rate.find_by(key: "gold").stale).to be(false)
    end
  end
end

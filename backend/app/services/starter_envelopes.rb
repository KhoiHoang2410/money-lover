# frozen_string_literal: true

# The single hard-coded set of suggested Envelopes the owner seeds their list
# from (CONTEXT.md "Starter envelopes"): name + icon, Allocation ₫0. One member
# is the designated Reserve, which becomes the Reserve only if none exists yet.
#
# Seeding is a one-time, idempotent action: an Envelope whose name already
# matches an existing one (case-insensitive, trimmed) is skipped, so re-applying
# never duplicates. Distinct from the recurring Allocation template.
module StarterEnvelopes
  # name + icon; the `reserve: true` member is the designated Reserve.
  SET = [
    { name: "Food",      icon: "fork.knife" },
    { name: "Rent",      icon: "house" },
    { name: "Transport", icon: "car" },
    { name: "Bills",     icon: "bolt" },
    { name: "Fun",       icon: "party.popper" },
    { name: "Reserve",   icon: "banknote", reserve: true }
  ].freeze

  module_function

  # Seeds the starter set onto `user`, skipping any name that already exists
  # (case-insensitive, trimmed). Designates the starter Reserve only when the
  # user has no Reserve yet. Returns nothing meaningful — the caller re-reads the
  # envelope list. Idempotent: a second call is a no-op.
  def seed!(user)
    existing = user.envelopes.pluck(:name).map { |name| normalize(name) }
    reserve_taken = user.envelopes.reserve.exists?

    SET.each do |spec|
      next if existing.include?(normalize(spec[:name]))

      is_reserve = spec[:reserve] == true && !reserve_taken
      user.envelopes.create!(
        name: spec[:name],
        icon: spec[:icon],
        is_reserve: is_reserve,
        currency: Envelope::BASE_CURRENCY,
        allocation_minor_units: 0
      )
      reserve_taken ||= is_reserve
    end
  end

  def normalize(name)
    name.to_s.strip.downcase
  end
end

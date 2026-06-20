# An Envelope owned by a User (CONTEXT.md): a named virtual bucket income is
# divided into (Food, Rent, Fun…). Tenant-scoped via Tenanted — only ever loaded
# through `current_user.envelopes`, so another user's row is unreachable, not
# merely hidden (ADR-0014).
#
# This is the persistence edge: it stores the Allocation / caps / carried as
# integer minor units + a currency code and exposes the domain `Money` value
# objects the pure BudgetEngine consumes — Float never crosses the boundary
# (ADR-0015). Per-month Allocation history lives in EnvelopeAllocation; the
# month's effective Allocation is `allocation_for(month)`.
class Envelope < ApplicationRecord
  include Tenanted

  BASE_CURRENCY = "VND".freeze

  has_many :allocations, class_name: "EnvelopeAllocation", dependent: :destroy,
                         inverse_of: :envelope

  validates :name, presence: true
  validates :currency, presence: true
  validate :only_one_reserve_per_user, if: :is_reserve?

  scope :reserve, -> { where(is_reserve: true) }

  # The default monthly Allocation (the Allocation-template default) as a `Money`.
  def allocation
    MoneyMapping.load(minor_units: allocation_minor_units || 0, currency: currency)
  end

  # The accumulated carry (the Reserve's running balance / a roll-over) as a `Money`.
  def carried
    MoneyMapping.load(minor_units: carried_minor_units || 0, currency: currency)
  end

  # Optional weekly / monthly cap as a `Money`, or nil when unset.
  def weekly_cap
    weekly_cap_minor_units && MoneyMapping.load(minor_units: weekly_cap_minor_units, currency: currency)
  end

  def monthly_cap
    monthly_cap_minor_units && MoneyMapping.load(minor_units: monthly_cap_minor_units, currency: currency)
  end

  # The effective Allocation for `month` (the first day of a month): the stored
  # per-month snapshot when present, otherwise the Envelope default. Lets a read
  # reflect a month a template was applied to without mutating the default.
  def allocation_for(month)
    snapshot = allocations.find { |a| a.month == month }
    return MoneyMapping.load(minor_units: snapshot.allocation_minor_units, currency: currency) if snapshot

    allocation
  end

  # This Envelope as a BudgetEngine value object for `month` (the pure engine
  # never sees ActiveRecord).
  def to_budget_envelope(month)
    BudgetEngine::Envelope.build(
      id: id,
      name: name,
      allocation: allocation_for(month),
      carried: carried,
      is_reserve: is_reserve
    )
  end

  private

  # Enforce "at most one Reserve per User" at the app edge (the partial unique
  # index is the backstop). A clear 422 beats a raw DB error on the race.
  def only_one_reserve_per_user
    clash = self.class.where(user_id: user_id, is_reserve: true).where.not(id: id)
    errors.add(:is_reserve, "a reserve envelope already exists") if clash.exists?
  end
end

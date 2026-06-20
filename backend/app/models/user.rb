class User < ApplicationRecord
  # The tenant. Every domain row is owned by exactly one User, and every query
  # is scoped through one of these associations so cross-tenant access is
  # structurally impossible (see Tenancy controller concern, ADR-0014).
  has_many :identities, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy
  # Transactions reference sources via a FK, so they must be torn down before
  # their sources when a User is destroyed — declared first for that order.
  has_many :transactions, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :rate_overrides, dependent: :destroy
  # Envelope allocations reference envelopes via a FK, so they are torn down
  # before their envelopes when a User is destroyed — declared first for order.
  has_many :envelope_allocations, dependent: :destroy
  has_many :envelopes, dependent: :destroy

  # Goals (issue 16). The AR class is GoalRecord (the bare Goal is the pure domain
  # value object); a Goal's balance is derived from tagged transfers, so there is
  # no FK from transactions to honour on teardown.
  has_many :goals, class_name: "GoalRecord", dependent: :destroy

  DEFAULT_TIMEZONE = "Asia/Ho_Chi_Minh".freeze

  # Timezone drives month boundaries / monthly resets / "today" in Signals.
  validates :timezone, presence: true
  validate :timezone_must_be_known

  private

  def timezone_must_be_known
    return if timezone.blank?
    return if ActiveSupport::TimeZone[timezone] || TZInfo::Timezone.all_identifiers.include?(timezone)

    errors.add(:timezone, "is not a recognized timezone")
  end
end

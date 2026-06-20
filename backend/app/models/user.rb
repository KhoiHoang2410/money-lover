class User < ApplicationRecord
  # The tenant. Every domain row is owned by exactly one User, and every query
  # is scoped through one of these associations so cross-tenant access is
  # structurally impossible (see Tenancy controller concern, ADR-0014).
  has_many :identities, dependent: :destroy

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

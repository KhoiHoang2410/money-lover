# A User's manual override of a global Rate (CONTEXT.md "Rate"). It wins for
# that User's valuations only; another User keeps seeing the global value. The
# authoritative cross-tenant boundary lives in the Tenancy controller concern —
# overrides are only ever loaded through `current_user.rate_overrides`.
class RateOverride < ApplicationRecord
  include Tenanted

  validates :key, presence: true, uniqueness: { scope: :user_id },
                  format: { with: Rate::KEY_PATTERN }
  validates :value, presence: true
end

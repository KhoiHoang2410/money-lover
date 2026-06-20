# Shared scope for every tenant-owned domain model (Account/Holding/Envelope/
# Goal/Transaction/rate override, issues 13–20). Including this declares the
# `belongs_to :user` ownership edge and a `for_user` scope. The authoritative
# enforcement lives in the Tenancy controller concern, which only ever loads
# rows *through* `current_user`'s association — so a row owned by another user
# is never reachable, not merely hidden (ADR-0014).
module Tenanted
  extend ActiveSupport::Concern

  included do
    belongs_to :user

    scope :for_user, ->(user) { where(user: user) }
  end
end

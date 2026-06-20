# Multi-tenant request scoping (ADR-0014). Mixed into Api::BaseController so
# every resource controller (issues 13–20) inherits:
#
#   * `current_user`        — the authenticated tenant.
#   * `tenant_scope(assoc)` — a relation rooted at the current user.
#   * `load_owned!(assoc,id)` — loads one of the current user's rows, or raises
#     ActiveRecord::RecordNotFound (→ 404) for anyone else's row.
#
# Because rows are only ever loaded *through* `current_user`, cross-tenant
# access is structurally impossible: there is no code path that fetches a row
# by bare id.
#
# SEAM FOR ISSUE 06: `current_user` is resolved here from the `X-User-Id`
# request header — a deliberate shim so this issue can test scoping without the
# JWT stack. Issue 06 replaces only `resolve_current_user` with bearer-token
# decoding; nothing else in this concern (or its callers) changes.
module Tenancy
  extend ActiveSupport::Concern

  CURRENT_USER_HEADER = "X-User-Id".freeze

  included do
    before_action :authenticate_user!
  end

  attr_reader :current_user

  private

  def authenticate_user!
    @current_user = resolve_current_user
    raise ApiError::Unauthorized unless @current_user
  end

  # ISSUE-06 SEAM: swap this body for JWT bearer decoding. Everything else that
  # depends on `current_user` keeps working unchanged.
  def resolve_current_user
    user_id = request.headers[CURRENT_USER_HEADER]
    return if user_id.blank?

    User.find_by(id: user_id)
  end

  # A relation rooted at the current tenant, e.g. tenant_scope(:identities).
  def tenant_scope(association)
    current_user.public_send(association)
  end

  # Load one of the current user's rows by id, or raise RecordNotFound for a
  # row that belongs to a different user (the authorization boundary).
  def load_owned!(association, id)
    tenant_scope(association).find(id)
  end
end

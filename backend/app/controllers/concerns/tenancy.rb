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
# Authentication is by bearer access token (ADR-0014): `resolve_current_user`
# verifies the JWT from the `Authorization: Bearer …` header and loads the User
# named by its `sub` claim. Tokens are issued by Auth::TokenService; the rest of
# this concern (tenant scoping / row-ownership) is independent of how the user
# is resolved.
module Tenancy
  extend ActiveSupport::Concern

  BEARER_SCHEME = "Bearer".freeze

  included do
    before_action :authenticate_user!
  end

  attr_reader :current_user

  private

  def authenticate_user!
    @current_user = resolve_current_user
    raise ApiError::Unauthorized unless @current_user
  end

  # Verify the bearer access token and load its subject. Any failure
  # (no/garbled/expired token, or an unknown subject) yields nil → 401.
  def resolve_current_user
    claims = Auth::TokenService.verify_access_token(bearer_token)
    return if claims.nil?

    User.find_by(id: claims["sub"])
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    scheme, token = header.split(" ", 2)
    return unless scheme == BEARER_SCHEME

    token
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

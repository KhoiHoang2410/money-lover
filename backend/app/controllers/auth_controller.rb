# Public authentication surface (ADR-0014, issue 06; webapp issue 01). These
# endpoints mint the tokens that the rest of the API (Api::BaseController via
# Tenancy) requires, so they themselves are unauthenticated — they inherit JSON
# + error handling from ApplicationController but deliberately NOT the Tenancy
# concern.
#
# Two clients, one surface (additive — ADR-0014):
#   * iOS (native): holds the access token in memory and the refresh token in
#     the Keychain, both read from the JSON body; sends the refresh token back
#     in the request body. Unaffected by the cookie below.
#   * Web (SPA): holds the access token in memory (JSON body) and lets the
#     refresh token live in an httpOnly cookie this controller sets and reads,
#     so JavaScript can never touch it.
#
# CSRF posture: the refresh cookie is `SameSite=Lax`, so the browser will NOT
# attach it to cross-site POSTs (a forged POST from evil.com to /auth/refresh
# carries no cookie and fails). `Path=/auth` keeps the cookie off every other
# endpoint, and refresh-token *rotation* (each use revokes the prior token)
# means even a leaked cookie is single-use. That is the baseline; if we later
# add browser GET routes that mutate state, add an anti-CSRF token then.
class AuthController < ApplicationController
  # ActionController::API omits the cookie jar; opt in for the refresh cookie.
  include ActionController::Cookies

  REFRESH_COOKIE = "refresh_token".freeze
  REFRESH_COOKIE_PATH = "/auth".freeze

  # POST /auth/register — create a User + password Identity, then auto-login.
  def register
    user = Auth::PasswordProvider.register(
      username: params.require(:username),
      password: params.require(:password),
      timezone: params[:timezone].presence || User::DEFAULT_TIMEZONE
    )
    issue_and_render(Auth::TokenService.issue_token_pair(user), status: :created)
  end

  # POST /auth/login — exchange credentials for an access + refresh pair.
  def login
    user = Auth::PasswordProvider.authenticate(
      username: params.require(:username),
      password: params.require(:password)
    )
    raise ApiError::Unauthorized.new("Invalid username or password.") unless user

    issue_and_render(Auth::TokenService.issue_token_pair(user), status: :ok)
  end

  # POST /auth/refresh — rotate the refresh token, returning a fresh pair. Reads
  # the token from the httpOnly cookie (web) or, failing that, the request body
  # (iOS) — so neither client has to change at once.
  def refresh
    pair = Auth::TokenService.rotate_refresh_token(presented_refresh_token)
    issue_and_render(pair, status: :ok)
  end

  # POST /auth/logout — revoke the refresh token (idempotent) and clear the
  # cookie so the browser stops presenting it.
  def logout
    Auth::TokenService.revoke_refresh_token(presented_refresh_token)
    clear_refresh_cookie
    head :no_content
  end

  private

  # Cookie first (web), then body (iOS). Either may be absent; the TokenService
  # treats a blank token as invalid, which is the correct rejection.
  def presented_refresh_token
    cookies[REFRESH_COOKIE].presence || params[:refresh_token]
  end

  # Set the rotating refresh token as an httpOnly cookie and render the pair
  # (access token + refresh token still in the body for the iOS client).
  def issue_and_render(pair, status:)
    set_refresh_cookie(pair[:refresh_token])
    render json: pair, status: status
  end

  def set_refresh_cookie(raw_token)
    cookies[REFRESH_COOKIE] = {
      value: raw_token,
      httponly: true,
      # Secure in every environment except local dev (http://localhost has no
      # TLS); ADR-0014 mandates Secure in production.
      secure: !Rails.env.development?,
      same_site: :lax,
      path: REFRESH_COOKIE_PATH,
      expires: Auth::TokenService::REFRESH_TOKEN_TTL.from_now
    }
  end

  def clear_refresh_cookie
    cookies.delete(REFRESH_COOKIE, path: REFRESH_COOKIE_PATH)
  end
end

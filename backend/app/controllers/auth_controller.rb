# Public authentication surface (ADR-0014, issue 06). These endpoints mint the
# tokens that the rest of the API (Api::BaseController via Tenancy) requires, so
# they themselves are unauthenticated — they inherit JSON + error handling from
# ApplicationController but deliberately NOT the Tenancy concern.
class AuthController < ApplicationController
  # POST /auth/register — create a User + password Identity, then auto-login.
  def register
    user = Auth::PasswordProvider.register(
      username: params.require(:username),
      password: params.require(:password),
      timezone: params[:timezone].presence || User::DEFAULT_TIMEZONE
    )
    render json: Auth::TokenService.issue_token_pair(user), status: :created
  end

  # POST /auth/login — exchange credentials for an access + refresh pair.
  def login
    user = Auth::PasswordProvider.authenticate(
      username: params.require(:username),
      password: params.require(:password)
    )
    raise ApiError::Unauthorized.new("Invalid username or password.") unless user

    render json: Auth::TokenService.issue_token_pair(user), status: :ok
  end

  # POST /auth/refresh — rotate the refresh token, returning a fresh pair.
  def refresh
    pair = Auth::TokenService.rotate_refresh_token(params.require(:refresh_token))
    render json: pair, status: :ok
  end

  # POST /auth/logout — revoke the refresh token (idempotent).
  def logout
    Auth::TokenService.revoke_refresh_token(params.require(:refresh_token))
    head :no_content
  end
end

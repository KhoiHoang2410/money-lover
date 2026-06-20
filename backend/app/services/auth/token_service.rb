require "jwt"
require "securerandom"

module Auth
  # Issues and verifies the auth tokens (ADR-0014, issue 06):
  #
  #   * a short-lived, stateless JWT *access* token (HS256, `sub` = user id),
  #     verified on every request by the Tenancy concern; and
  #   * a long-lived, rotating *refresh* token persisted (digest-only) as a
  #     RefreshToken row, so it can be revoked.
  #
  # Rotation is the security property: using a refresh token revokes it and
  # mints a fresh pair, so a captured-and-replayed refresh token is rejected.
  module TokenService
    module_function

    ACCESS_TOKEN_TTL = 15.minutes
    REFRESH_TOKEN_TTL = 30.days
    ALGORITHM = "HS256".freeze
    ACCESS_TOKEN_TYPE = "access".freeze
    REFRESH_TOKEN_BYTES = 48

    # The login response: a new access token + a fresh refresh token.
    def issue_token_pair(user, now: Time.current)
      {
        access_token: issue_access_token(user, now: now),
        refresh_token: issue_refresh_token(user, now: now),
        token_type: "Bearer",
        expires_in: ACCESS_TOKEN_TTL.to_i
      }
    end

    def issue_access_token(user, now: Time.current)
      payload = {
        sub: user.id,
        type: ACCESS_TOKEN_TYPE,
        iat: now.to_i,
        exp: (now + ACCESS_TOKEN_TTL).to_i
      }
      JWT.encode(payload, secret, ALGORITHM)
    end

    # Decode + verify an access token, returning its claims, or nil if the token
    # is missing, malformed, tampered, expired, or not an access token. Callers
    # (Tenancy) treat nil as "unauthenticated".
    def verify_access_token(token)
      return if token.blank?

      claims, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
      return unless claims["type"] == ACCESS_TOKEN_TYPE

      claims
    rescue JWT::DecodeError
      nil
    end

    # Mint and persist a refresh token; returns the raw token (the only place it
    # exists in the clear — the database keeps just its digest).
    def issue_refresh_token(user, now: Time.current)
      raw_token = SecureRandom.urlsafe_base64(REFRESH_TOKEN_BYTES)
      user.refresh_tokens.create!(
        token_digest: RefreshToken.digest_for(raw_token),
        expires_at: now + REFRESH_TOKEN_TTL
      )
      raw_token
    end

    # Rotate: revoke the presented refresh token and return a brand-new pair.
    # Raises Unauthorized when the token is unknown, already rotated, revoked, or
    # expired — which is exactly how reuse-after-rotation is rejected.
    def rotate_refresh_token(raw_token, now: Time.current)
      record = active_refresh_token(raw_token)
      raise ApiError::Unauthorized.new("Refresh token is invalid or expired.") unless record

      record.revoke!
      issue_token_pair(record.user, now: now)
    end

    # Logout: revoke the refresh token if it is still active. Idempotent —
    # returns whether a live token was actually revoked.
    def revoke_refresh_token(raw_token)
      record = active_refresh_token(raw_token)
      record&.revoke!
      record.present?
    end

    def active_refresh_token(raw_token)
      return if raw_token.blank?

      RefreshToken.active.find_by(token_digest: RefreshToken.digest_for(raw_token))
    end

    # The HMAC signing key. secret_key_base is present in every environment
    # (auto-generated in test/dev, from credentials/ENV in production).
    def secret
      Rails.application.secret_key_base
    end
  end
end

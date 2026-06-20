require "rails_helper"

RSpec.describe Auth::TokenService, type: :model do
  let(:user) { Auth::PasswordProvider.register(username: "alice", password: "secret123") }

  describe ".issue_access_token / .verify_access_token" do
    it "round-trips: a freshly issued access token verifies to its subject" do
      token = described_class.issue_access_token(user)

      claims = described_class.verify_access_token(token)
      expect(claims["sub"]).to eq(user.id)
      expect(claims["type"]).to eq("access")
    end

    it "rejects a tampered/garbage token" do
      expect(described_class.verify_access_token("not.a.jwt")).to be_nil
    end

    it "rejects a blank token" do
      expect(described_class.verify_access_token(nil)).to be_nil
      expect(described_class.verify_access_token("")).to be_nil
    end

    it "rejects an expired access token" do
      issued_at = described_class::ACCESS_TOKEN_TTL.ago - 1.minute
      token = described_class.issue_access_token(user, now: issued_at)

      expect(described_class.verify_access_token(token)).to be_nil
    end

    it "rejects a token signed with a different secret" do
      foreign = JWT.encode({ sub: user.id, type: "access", exp: 1.hour.from_now.to_i }, "wrong-secret", "HS256")

      expect(described_class.verify_access_token(foreign)).to be_nil
    end

    it "rejects a non-access token type" do
      payload = { sub: user.id, type: "refresh", exp: 1.hour.from_now.to_i }
      token = JWT.encode(payload, described_class.secret, "HS256")

      expect(described_class.verify_access_token(token)).to be_nil
    end
  end

  describe ".issue_token_pair" do
    it "returns an access + refresh token and a Bearer envelope" do
      pair = described_class.issue_token_pair(user)

      expect(pair[:token_type]).to eq("Bearer")
      expect(pair[:expires_in]).to eq(described_class::ACCESS_TOKEN_TTL.to_i)
      expect(described_class.verify_access_token(pair[:access_token])["sub"]).to eq(user.id)
      expect(pair[:refresh_token]).to be_present
    end

    it "persists only the refresh token's digest, never the raw token" do
      pair = described_class.issue_token_pair(user)

      stored = user.refresh_tokens.sole
      expect(stored.token_digest).to eq(RefreshToken.digest_for(pair[:refresh_token]))
      expect(RefreshToken.pluck(:token_digest)).not_to include(pair[:refresh_token])
    end
  end

  describe ".rotate_refresh_token" do
    it "revokes the old refresh token and issues a new pair" do
      original = described_class.issue_refresh_token(user)

      rotated = described_class.rotate_refresh_token(original)

      expect(rotated[:access_token]).to be_present
      expect(rotated[:refresh_token]).to be_present
      expect(rotated[:refresh_token]).not_to eq(original)
      expect(user.refresh_tokens.active.count).to eq(1)
    end

    it "rejects reusing a refresh token that was already rotated" do
      original = described_class.issue_refresh_token(user)
      described_class.rotate_refresh_token(original)

      expect { described_class.rotate_refresh_token(original) }
        .to raise_error(ApiError::Unauthorized)
    end

    it "rejects an unknown refresh token" do
      expect { described_class.rotate_refresh_token("nonexistent") }
        .to raise_error(ApiError::Unauthorized)
    end

    it "rejects an expired refresh token" do
      described_class.issue_refresh_token(user, now: described_class::REFRESH_TOKEN_TTL.ago - 1.day)
      raw = SecureRandom.urlsafe_base64(48)
      user.refresh_tokens.create!(
        token_digest: RefreshToken.digest_for(raw),
        expires_at: 1.day.ago
      )

      expect { described_class.rotate_refresh_token(raw) }
        .to raise_error(ApiError::Unauthorized)
    end
  end

  describe ".revoke_refresh_token" do
    it "revokes an active refresh token so it can no longer be rotated" do
      raw = described_class.issue_refresh_token(user)

      expect(described_class.revoke_refresh_token(raw)).to be(true)
      expect { described_class.rotate_refresh_token(raw) }
        .to raise_error(ApiError::Unauthorized)
    end

    it "is a no-op for an unknown token" do
      expect(described_class.revoke_refresh_token("nope")).to be(false)
    end
  end
end

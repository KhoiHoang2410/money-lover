require "rails_helper"

RSpec.describe RefreshToken, type: :model do
  let(:user) { Auth::PasswordProvider.register(username: "alice", password: "secret123") }

  def build_token(expires_at: 1.day.from_now, revoked_at: nil)
    user.refresh_tokens.create!(
      token_digest: described_class.digest_for(SecureRandom.hex(16)),
      expires_at: expires_at,
      revoked_at: revoked_at
    )
  end

  describe ".active" do
    it "includes a token that is neither revoked nor expired" do
      token = build_token
      expect(described_class.active).to include(token)
    end

    it "excludes a revoked token" do
      token = build_token(revoked_at: Time.current)
      expect(described_class.active).not_to include(token)
    end

    it "excludes an expired token" do
      token = build_token(expires_at: 1.minute.ago)
      expect(described_class.active).not_to include(token)
    end
  end

  describe "#revoke!" do
    it "stamps revoked_at and drops the row from active" do
      token = build_token
      token.revoke!
      expect(token.revoked_at).to be_present
      expect(described_class.active).not_to include(token)
    end
  end

  describe ".digest_for" do
    it "is deterministic and does not echo the raw token" do
      raw = "a-secret-token"
      expect(described_class.digest_for(raw)).to eq(described_class.digest_for(raw))
      expect(described_class.digest_for(raw)).not_to eq(raw)
    end
  end
end

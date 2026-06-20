require "digest"

# A long-lived refresh token for one User (ADR-0014). The raw token is a
# high-entropy random string handed to the client; only its SHA-256 digest is
# persisted. Refresh tokens rotate (each use revokes the old row and issues a
# new pair) and are revoked on logout — so a leaked or replayed token is inert.
class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Usable tokens: not revoked and not past expiry.
  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current..) }

  # The stored digest of a raw token. High-entropy input means a fast SHA-256 is
  # sufficient (unlike low-entropy passwords, which need bcrypt).
  def self.digest_for(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def active?
    revoked_at.nil? && expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end

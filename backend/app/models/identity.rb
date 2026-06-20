class Identity < ApplicationRecord
  # A single login method for a User: a (provider, external_id) pair.
  belongs_to :user

  # The only provider that ships now. `google` (and others) are added later as
  # new rows with this column set differently — no schema migration (ADR-0014).
  PASSWORD = "password".freeze

  # Adds #authenticate and the #password=/#password_confirmation setters backed
  # by bcrypt. validations: false because non-password providers (e.g. google)
  # legitimately have no password_digest; we validate it ourselves below.
  has_secure_password validations: false

  validates :provider, presence: true
  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :provider, case_sensitive: true }
  validates :password_digest, presence: true, if: :password_provider?

  scope :for_provider, ->(provider) { where(provider: provider) }

  # Look up a login method by its provider + external id (username/email/sub).
  def self.find_by_credentials(provider:, external_id:)
    find_by(provider: provider, external_id: external_id)
  end

  def password_provider?
    provider == PASSWORD
  end
end

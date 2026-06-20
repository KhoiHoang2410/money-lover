module Auth
  # The `password` identity provider: register a brand-new User with a
  # username/password login, and verify credentials on sign-in. Issue 06 layers
  # JWT issuance on top of #authenticate; this service owns the credential math.
  module PasswordProvider
    module_function

    # Create a User and its password Identity atomically. Raises
    # ActiveRecord::RecordInvalid on a duplicate username or weak input.
    def register(username:, password:, timezone: User::DEFAULT_TIMEZONE)
      User.transaction do
        user = User.create!(timezone: timezone)
        user.identities.create!(
          provider: Identity::PASSWORD,
          external_id: username,
          password: password
        )
        user
      end
    end

    # Return the owning User when the credentials match, otherwise nil. Always
    # runs bcrypt#authenticate so a missing username and a wrong password cost
    # roughly the same (no user-enumeration timing signal).
    def authenticate(username:, password:)
      identity = Identity.find_by_credentials(
        provider: Identity::PASSWORD,
        external_id: username
      )
      identity ||= Identity.new(password_digest: BCrypt::Password.create("x"))
      identity.authenticate(password) ? identity.user : nil
    end
  end
end

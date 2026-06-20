require "rails_helper"

RSpec.describe Auth::PasswordProvider, type: :model do
  describe ".register" do
    it "creates a user with a password identity and a default timezone" do
      user = described_class.register(username: "alice", password: "secret123")

      expect(user).to be_persisted
      expect(user.timezone).to eq(User::DEFAULT_TIMEZONE)
      identity = user.identities.sole
      expect(identity.provider).to eq(Identity::PASSWORD)
      expect(identity.external_id).to eq("alice")
      expect(identity.authenticate("secret123")).to be_truthy
    end

    it "honors a supplied timezone" do
      user = described_class.register(username: "bob", password: "secret123", timezone: "Europe/London")
      expect(user.timezone).to eq("Europe/London")
    end

    it "rolls back the user when the username is taken" do
      described_class.register(username: "alice", password: "secret123")

      expect {
        expect {
          described_class.register(username: "alice", password: "different1")
        }.to raise_error(ActiveRecord::RecordInvalid)
      }.not_to change(User, :count)
    end
  end

  describe ".authenticate" do
    before { described_class.register(username: "alice", password: "secret123") }

    it "returns the user for valid credentials" do
      user = described_class.authenticate(username: "alice", password: "secret123")
      expect(user).to be_a(User)
      expect(user.identities.first.external_id).to eq("alice")
    end

    it "returns nil for a wrong password" do
      expect(described_class.authenticate(username: "alice", password: "nope")).to be_nil
    end

    it "returns nil for an unknown username" do
      expect(described_class.authenticate(username: "ghost", password: "secret123")).to be_nil
    end
  end
end

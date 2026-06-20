require "rails_helper"

RSpec.describe Identity, type: :model do
  let(:user) { User.create! }

  it "creates a password identity with a bcrypt digest, never storing the plaintext" do
    identity = user.identities.create!(
      provider: Identity::PASSWORD,
      external_id: "alice",
      password: "secret123"
    )

    expect(identity.password_digest).to be_present
    expect(identity.password_digest).not_to include("secret123")
  end

  it "verifies a correct password and rejects a wrong one" do
    identity = user.identities.create!(
      provider: Identity::PASSWORD,
      external_id: "alice",
      password: "secret123"
    )

    expect(identity.authenticate("secret123")).to eq(identity)
    expect(identity.authenticate("wrong")).to be(false)
  end

  it "requires a password digest for the password provider" do
    identity = user.identities.build(provider: Identity::PASSWORD, external_id: "alice")
    expect(identity).not_to be_valid
    expect(identity.errors[:password_digest]).to be_present
  end

  it "allows a non-password provider to omit the digest (future google login)" do
    identity = user.identities.build(provider: "google", external_id: "google-sub-123")
    expect(identity).to be_valid
  end

  it "enforces a unique (provider, external_id) pair" do
    user.identities.create!(provider: Identity::PASSWORD, external_id: "alice", password: "secret123")

    dup = User.create!.identities.build(
      provider: Identity::PASSWORD,
      external_id: "alice",
      password: "another1"
    )
    expect(dup).not_to be_valid
    expect(dup.errors[:external_id]).to be_present
  end

  it "looks up an identity by provider and external id" do
    identity = user.identities.create!(provider: Identity::PASSWORD, external_id: "alice", password: "secret123")

    found = Identity.find_by_credentials(provider: Identity::PASSWORD, external_id: "alice")
    expect(found).to eq(identity)
    expect(Identity.find_by_credentials(provider: Identity::PASSWORD, external_id: "ghost")).to be_nil
  end
end

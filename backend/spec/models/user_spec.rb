require "rails_helper"

RSpec.describe User, type: :model do
  it "defaults to the base-currency timezone and persists a custom one" do
    expect(User.create!.timezone).to eq("Asia/Ho_Chi_Minh")

    user = User.create!(timezone: "America/New_York")
    expect(User.find(user.id).timezone).to eq("America/New_York")
  end

  it "rejects a blank timezone" do
    user = User.new(timezone: "")
    expect(user).not_to be_valid
    expect(user.errors[:timezone]).to be_present
  end

  it "rejects an unrecognized timezone" do
    user = User.new(timezone: "Mars/Olympus_Mons")
    expect(user).not_to be_valid
    expect(user.errors[:timezone]).to be_present
  end

  it "owns its identities and cascades deletion" do
    user = User.create!
    user.identities.create!(provider: Identity::PASSWORD, external_id: "alice", password: "secret123")

    expect { user.destroy! }.to change(Identity, :count).by(-1)
  end
end

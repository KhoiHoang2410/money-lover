require "rails_helper"

# Envelope model (issue 15): the tenant-scoped budgeting bucket. The behaviour
# that carries money/invariant risk is the exactly-one-Reserve rule and the
# per-month Allocation resolution (snapshot, else default) the read path relies on.
RSpec.describe Envelope, type: :model do
  let(:user) { Auth::PasswordProvider.register(username: "alice", password: "secret123") }

  def build_envelope(**attrs)
    user.envelopes.new({ name: "Food", currency: "VND" }.merge(attrs))
  end

  describe "the exactly-one-Reserve invariant" do
    it "rejects a second reserve for the same user" do
      build_envelope(name: "Reserve", is_reserve: true).save!

      second = build_envelope(name: "Backup", is_reserve: true)

      expect(second).not_to be_valid
      expect(second.errors[:is_reserve]).to be_present
    end

    it "allows many non-reserve envelopes" do
      build_envelope(name: "Food").save!
      expect(build_envelope(name: "Rent")).to be_valid
    end

    it "scopes the invariant per user" do
      build_envelope(name: "Reserve", is_reserve: true).save!
      bob = Auth::PasswordProvider.register(username: "bob", password: "secret123")

      expect(bob.envelopes.new(name: "Reserve", currency: "VND", is_reserve: true)).to be_valid
    end
  end

  describe "#allocation_for" do
    it "returns the per-month snapshot when present" do
      envelope = build_envelope(allocation_minor_units: 1_000)
      envelope.save!
      envelope.allocations.create!(user: user, month: Date.new(2026, 6, 1),
                                   allocation_minor_units: 5_000, currency: "VND")

      expect(envelope.allocation_for(Date.new(2026, 6, 1))).to eq(Money.new(minor_units: 5_000, currency: :VND))
    end

    it "falls back to the default allocation when no snapshot exists" do
      envelope = build_envelope(allocation_minor_units: 1_000)
      envelope.save!

      expect(envelope.allocation_for(Date.new(2026, 6, 1))).to eq(Money.new(minor_units: 1_000, currency: :VND))
    end
  end
end

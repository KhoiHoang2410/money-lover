require "rails_helper"

# Signals API (issue 20). Asserts the computed Signals for a known ledger,
# per-User isolation, auth, and OpenAPI conformance (the contract gate bites via
# assert_conforms_to_contract).
RSpec.describe "Api::Signals", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  def json_headers(user)
    headers = { "Accept" => "application/json", "Content-Type" => "application/json" }
    headers["Authorization"] = "Bearer #{Auth::TokenService.issue_access_token(user)}" if user
    headers
  end

  let(:alice) { Auth::PasswordProvider.register(username: "alice", password: "secret123") }
  let(:bob)   { Auth::PasswordProvider.register(username: "bob",   password: "secret123") }

  # Pin "today" to mid-month so the linear-pace rule is exercised deterministically
  # (15 June 2026, June = 30 days → elapsed 15/30).
  before { travel_to(Time.utc(2026, 6, 15, 12)) }
  after  { travel_back }

  def account_for(user)
    user.sources.create!(kind: Source::ACCOUNT, name: "Cash", currency: Source::BASE_CURRENCY)
  end

  describe "GET /signals" do
    it "computes the caller's signals and conforms to the contract" do
      account = account_for(alice)
      food = alice.envelopes.create!(name: "Food", currency: "VND", allocation_minor_units: 1_000_000)
      # 600k by day 15/30 → projected to overrun: 600k·30 > 1M·15.
      alice.transactions.create!(
        kind: Transaction::EXPENSE, source: account, amount_minor_units: 600_000,
        currency: "VND", envelope_id: food.id, occurred_on: Date.new(2026, 6, 10)
      )

      get "/signals", headers: json_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)

      signals = response.parsed_body.fetch("signals")
      pace = signals.find { |s| s["kind"] == "projectedOverspend" }
      expect(pace).not_to be_nil
      expect(pace["id"]).to eq("projectedOverspend-#{food.id}")
      expect(pace["severity"]).to eq("warning")
      expect(pace["detail"]).to include("₫600,000")
    end

    it "orders signals strongest-first" do
      account = account_for(alice)
      food = alice.envelopes.create!(name: "Food", currency: "VND", allocation_minor_units: 1_000_000)
      # Critical overspend on Food + an info large-expense among three expenses.
      alice.transactions.create!(kind: Transaction::EXPENSE, source: account, amount_minor_units: 1_200_000,
                                 currency: "VND", envelope_id: food.id, occurred_on: Date.new(2026, 6, 5))
      alice.transactions.create!(kind: Transaction::EXPENSE, source: account, amount_minor_units: 100_000,
                                 currency: "VND", occurred_on: Date.new(2026, 6, 6))
      alice.transactions.create!(kind: Transaction::EXPENSE, source: account, amount_minor_units: 2_000_000,
                                 currency: "VND", note: "TV", occurred_on: Date.new(2026, 6, 7))

      get "/signals", headers: json_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      severities = response.parsed_body.fetch("signals").map { |s| s["severity"] }
      expect(severities.first).to eq("critical")
      expect(severities.last).to eq("info")
    end

    it "returns an empty list when nothing fires" do
      account = account_for(alice)
      food = alice.envelopes.create!(name: "Food", currency: "VND", allocation_minor_units: 1_000_000)
      alice.transactions.create!(kind: Transaction::EXPENSE, source: account, amount_minor_units: 100_000,
                                 currency: "VND", envelope_id: food.id, occurred_on: Date.new(2026, 6, 10))

      get "/signals", headers: json_headers(alice)

      expect(response).to have_http_status(:ok)
      assert_conforms_to_contract(200)
      expect(response.parsed_body.fetch("signals")).to be_empty
    end

    it "isolates one user's signals from another's data" do
      account = account_for(bob)
      food = bob.envelopes.create!(name: "Food", currency: "VND", allocation_minor_units: 1_000_000)
      bob.transactions.create!(kind: Transaction::EXPENSE, source: account, amount_minor_units: 1_200_000,
                               currency: "VND", envelope_id: food.id, occurred_on: Date.new(2026, 6, 10))

      get "/signals", headers: json_headers(alice)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("signals")).to be_empty
    end

    it "rejects an unauthenticated request" do
      get "/signals", headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
      assert_conforms_to_contract(401)
      expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
    end
  end
end

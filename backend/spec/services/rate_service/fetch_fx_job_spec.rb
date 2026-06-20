require "rails_helper"

# The fetch jobs are network-isolated here: we stub the private fetch and feed
# the captured upstream fixture, then assert the populate / stale-fallback paths
# the acceptance criteria require.
RSpec.describe RateService::FetchFxJob do
  let(:body) { File.read(Rails.root.join("spec/fixtures/rates/fx_upstream.json")) }

  it "populates/refreshes the global fx.* rates on a successful fetch" do
    allow_any_instance_of(described_class).to receive(:fetch_body).and_return(body)

    described_class.new.perform

    rate = Rate.find_by(key: "fx.USD")
    expect(rate.value).to eq(BigDecimal("25500"))
    expect(rate.source).to eq("fx")
    expect(rate.stale).to be(false)
    expect(rate.fetched_at).to be_present
  end

  it "serves the last cached value flagged stale when the fetch fails (no crash)" do
    Rate.create!(key: "fx.USD", value: BigDecimal("25000"), source: "fx",
                 fetched_at: 1.day.ago, stale: false)
    allow_any_instance_of(described_class).to receive(:fetch_body)
      .and_raise(SocketError, "getaddrinfo failed")

    expect { described_class.new.perform }.not_to raise_error

    rate = Rate.find_by(key: "fx.USD")
    expect(rate.value).to eq(BigDecimal("25000")) # last good value preserved
    expect(rate.stale).to be(true)
  end

  it "enqueues onto Sidekiq" do
    require "sidekiq/testing"
    Sidekiq::Testing.fake! do
      described_class.clear
      expect { described_class.perform_async }.to change(described_class.jobs, :size).by(1)
    end
  end
end

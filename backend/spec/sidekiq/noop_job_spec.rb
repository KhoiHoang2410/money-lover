require "rails_helper"
require "sidekiq/testing"

RSpec.describe NoopJob do
  before do
    Sidekiq::Testing.fake!
    NoopJob.clear
  end

  after { Sidekiq::Testing.disable! }

  it "enqueues onto Sidekiq" do
    expect { NoopJob.perform_async }.to change(NoopJob.jobs, :size).by(1)
  end

  it "runs without error when drained" do
    NoopJob.perform_async

    expect { NoopJob.drain }.not_to raise_error
    expect(NoopJob.jobs).to be_empty
  end
end

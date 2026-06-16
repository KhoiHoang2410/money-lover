class NoopJob
  include Sidekiq::Job

  def perform(*)
  end
end

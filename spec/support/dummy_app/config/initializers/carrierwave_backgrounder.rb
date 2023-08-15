queue_adapter = ENV['QUEUE_ADAPTER'] || :active_job
CarrierWave::Backgrounder.configure do |c|
  c.backend queue_adapter.to_sym, queue: :carrierwave
  # c.backend :sidekiq, queue: :carrierwave
end
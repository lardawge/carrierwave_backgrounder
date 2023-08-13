CarrierWave::Backgrounder.configure do |c|
  c.backend :active_job, queue: :carrierwave
  # c.backend :sidekiq, queue: :carrierwave
end

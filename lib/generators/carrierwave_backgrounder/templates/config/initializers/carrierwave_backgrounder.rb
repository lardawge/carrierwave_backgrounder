CarrierWave::Backgrounder.configure do |c|
  c.backend :active_job, queue: :carrierwave
  # c.backend :sidekiq, queue: :carrierwave

  ## Uncomment if you would like a NotFoundError raised if a record is deleted before processing
  # c.suppress_record_not_found_errors false
end

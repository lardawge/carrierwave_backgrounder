require 'active_job'
require 'sidekiq'

backend = ENV['BACKEND'] || :active_job

CarrierWave::Backgrounder.configure do |c|
  c.backend backend.to_sym, queue: :carrierwave
end

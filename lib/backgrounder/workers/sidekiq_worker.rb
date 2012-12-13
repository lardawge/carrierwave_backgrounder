# encoding: utf-8
begin
  require "sidekiq"
  
  class CarrierWave::Workers::SidekiqWorker
    include ::Sidekiq::Worker
    
    def perform(*args)
      worker = args.shift
      worker.constantize.perform(*args)
    end
  end
rescue LoadError => e
  # missing skip
end


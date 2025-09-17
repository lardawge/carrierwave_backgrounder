class DocumentUploaderSidekiqJob < ::CarrierWave::Workers::StoreAsset
  include Sidekiq::Job
end

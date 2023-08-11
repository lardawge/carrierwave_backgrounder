# encoding: utf-8
require active_job

module CarrierWave
  module Workers
    module ActiveJob

      class StoreAsset < ::ActiveJob::Base
        include CarrierWave::Workers::StoreAssetMixin
      end

    end # ActiveJob
  end # Workers
end # Backgrounder
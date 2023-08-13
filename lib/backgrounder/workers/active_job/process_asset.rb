# encoding: utf-8
require active_job

module CarrierWave
  module Workers
    module ActiveJob

      class ProcessAsset < ::ActiveJob::Base
        include CarrierWave::Workers::ProcessAssetMixin
      end

    end # ActiveJob
  end # Workers
end # Backgrounder
# encoding: utf-8
require 'backgrounder/workers/process_asset_mixin'

module CarrierWave
  module Workers

    class ProcessAsset
      include CarrierWave::Workers::ProcessAssetMixin
    end # ProcessAsset

  end # Workers
end # Backgrounder

# encoding: utf-8
require 'backgrounder/workers/store_asset_mixin'

module CarrierWave
  module Workers

    class StoreAsset
      include CarrierWave::Workers::StoreAssetMixin
    end # StoreAsset

  end # Workers
end # Backgrounder

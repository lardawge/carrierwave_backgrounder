# encoding: utf-8
module CarrierWave
  module Workers

    module StoreAssetMixin
      include CarrierWave::Workers::Base

      def self.included(base)
        base.extend CarrierWave::Workers::ClassMethods
      end

      def perform(*args)
        record = super(*args)

        return unless record && record.send(:"#{column}_tmp")

        record.send :"process_#{column}_upload=", true
        record.send :"#{column}_cache=", record.send(:"#{column}_tmp")  # Set the cache path
        cache_assets! record.send(:"#{column}")                         # Trigger version creation
        store_assets! record.send(:"#{column}")                         # Store the files
        record.send :"#{column}_tmp=", nil
        record.send :"#{column}_processing=", false if record.respond_to?(:"#{column}_processing")
        record.save!
      end

      private

      def cache_assets!(asset)
        asset.is_a?(Array) ? asset.map(&:cache!) : asset.cache!
      end

      def store_assets!(asset)
        asset.is_a?(Array) ? asset.map(&:store!) : asset.store!
      end
    end # StoreAssetMixin

  end # Workers
end # Backgrounder

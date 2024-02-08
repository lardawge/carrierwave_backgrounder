module CarrierWave
  module Workers
    module ProcessAssetMixin
      include CarrierWave::Workers::Base

      def self.included(base)
        base.extend CarrierWave::Workers::ClassMethods
      end

      def perform(*args)
        record = super(*args)
        record.send(:"process_#{column}_upload=", true)
        asset = record.send(:"#{column}")

        return unless record && asset_present?(asset)

        process_asset_by_cache!(asset)

        return unless record.respond_to?(:"#{column}_processing")

        record.update_attribute :"#{column}_processing", false
      end

      private

      def process_asset_by_cache!(asset)
        asset.is_a?(Array) ? asset.map(&:cache!) : asset.cache!
      end

      def asset_present?(asset)
        asset.is_a?(Array) ? asset.present? : asset.file.present?
      end
    end # ProcessAssetMixin
  end # Workers
end # Backgrounder

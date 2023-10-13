# encoding: utf-8
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

        recreate_asset_versions!(asset)

        if record.respond_to?(:"#{column}_processing")
          record.update_attribute :"#{column}_processing", false
        end
      end

      private

      def recreate_asset_versions!(asset)
        asset.is_a?(Array) ? asset.map(&:recreate_versions!) : asset.recreate_versions!
      end

      def asset_present?(asset)
        asset.is_a?(Array) ? asset.present? : asset.file.present?
      end
    end # ProcessAssetMixin

  end # Workers
end # Backgrounder

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

        if record && record.send(:"#{column}").present?
          record.send(:"process_#{column}_upload=", true)
          if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
            record.update_attribute :"#{column}_processing", false
          end
        else
          when_not_ready
        end
      end

    end # ProcessAssetMixin

  end # Workers
end # Backgrounder

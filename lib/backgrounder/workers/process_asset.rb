# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Base

      def perform(*args)
        record = super(*args)

        if record && record.send(:"#{column}").present?
          record.send(:"process_#{column}_upload=", true)
          if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
            record.update_attribute :"#{column}_processing", false
          end
          if record.respond_to?(:"#{column}_processed")
            record.update_attribute :"#{column}_processed", true
          end          
        end
      end

    end # ProcessAsset

  end # Workers
end # Backgrounder

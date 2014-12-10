# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Base

      def perform(*args)
        record = super(*args)

        if record
          # Ensure the file is still present, it may have been removed before this background job got to run.
          if record.send(:"#{column}").file.present?
            record.send(:"process_#{column}_upload=", true)
            if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
              record.update_attribute :"#{column}_processing", false
            end
          end
        end
      end

    end # ProcessAsset

  end # Workers
end # Backgrounder

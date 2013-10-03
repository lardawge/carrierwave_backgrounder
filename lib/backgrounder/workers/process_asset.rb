# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Base

      def perform(*args)
        record = super(*args)

        if record
          record.send(:"process_#{column}_upload=", true)
          uploader = record.send(:"#{column}")
          if uploader.recreate_versions! && record.respond_to?(:"#{column}_processing")
            record.update_attribute :"#{column}_processing", nil
          end

          store_filename = record[:"#{column}"]
          if store_filename != uploader.filename
            record.save!
          end
        end
      end

    end # ProcessAsset

  end # Workers
end # Backgrounder

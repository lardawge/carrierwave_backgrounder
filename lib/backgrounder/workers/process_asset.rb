# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Base

      def perform(*args)
        original_search_path = ActiveRecord::Base.connection.schema_search_path
        ActiveRecord::Base.connection.schema_search_path = "practice#{schema_id},public"
        record = super(*args)

        if record
          record.send(:"process_#{column}_upload=", true)
          if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
            record.update_attribute :"#{column}_processing", nil
          end
        end
        ensure
          ActiveRecord::Base.connection.schema_search_path = original_search_path
      end

    end # ProcessAsset

  end # Workers
end # Backgrounder

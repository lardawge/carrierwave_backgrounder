# encoding: utf-8
module CarrierWave
  module Workers

    class StoreAsset < Base
      attr_reader :cache_path, :tmp_directory

      def perform(*args)
        original_search_path = ActiveRecord::Base.connection.schema_search_path
        ActiveRecord::Base.connection.schema_search_path = "practice#{schema_id},public"

        record = super(*args)

        if record.send(:"#{column}_tmp")
          store_directories(record)
          record.send :"process_#{column}_upload=", true
          record.send :"#{column}_tmp=", nil
          record.send :"#{column}_processing=", nil if record.respond_to?(:"#{column}_processing")
          File.open(cache_path) { |f| record.send :"#{column}=", f }
          if record.save!
            FileUtils.rm_r(tmp_directory, :force => true)
          end
        end
        #ensure
        #  ActiveRecord::Base.connection.schema_search_path = original_search_path
      end

      private

      def store_directories(record)
        asset, asset_tmp = record.send(:"#{column}"), record.send(:"#{column}_tmp")
        cache_directory  = File.expand_path(asset.cache_dir, asset.root)
        @cache_path      = File.join(cache_directory, asset_tmp)
        @tmp_directory   = File.join(cache_directory, asset_tmp.split("/").first)
      end
    end # StoreAsset

  end # Workers
end # Backgrounder

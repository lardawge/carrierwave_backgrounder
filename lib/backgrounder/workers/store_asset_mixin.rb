# encoding: utf-8
module CarrierWave
  module Workers

    module StoreAssetMixin
      include CarrierWave::Workers::Base

      def self.included(base)
        base.extend CarrierWave::Workers::ClassMethods
      end

      attr_reader :cache_path, :tmp_directory

      def perform(*args)
        record = super(*args)

        if record && record.send(:"#{column}_tmp")
          store_directories(record)
          record.send :"process_#{column}_upload=", true
          record.send :"#{column}_tmp=", nil
          record.send :"#{column}_processing=", false if record.respond_to?(:"#{column}_processing")
          File.open(cache_path) { |f| record.send :"#{column}=", f }
          if record.save!
            FileUtils.rm_r(tmp_directory, :force => true)
          end
        else
          when_not_ready
        end
      end

      private

      def store_directories(record)
        asset, asset_tmp = record.send(:"#{column}"), record.send(:"#{column}_tmp")
        cache_directory  = File.expand_path(asset.cache_dir, asset.root)
        @cache_path      = File.join(cache_directory, asset_tmp)
        @tmp_directory   = File.join(cache_directory, asset_tmp.split("/").first)
      end

    end # StoreAssetMixin

  end # Workers
end # Backgrounder

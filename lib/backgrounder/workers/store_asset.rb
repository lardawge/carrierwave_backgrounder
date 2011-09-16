# encoding: utf-8
module CarrierWave
  module Workers

    class StoreAsset < Struct.new(:klass, :id, :column)
      @queue = :store_asset

      def self.perform(*args)
        new(*args).perform
      end

      def perform
        record = klass.constantize.find id
        if tmp = record.send(:"#{column}_tmp")
          asset = record.send(:"#{column}")
          cache_dir  = [asset.root, asset.cache_dir].join("/")
          cache_path = [cache_dir, tmp].join("/")
        
          record.send :"process_#{column}_upload=", true
          record.send :"#{column}_tmp=", nil
          File.open(cache_path) { |f| record.send :"#{column}=", f }
          if record.save!
            FileUtils.rm(cache_path)
          end
        end
      end
      
    end # StoreAsset
    
  end # Workers
end # Backgrounder

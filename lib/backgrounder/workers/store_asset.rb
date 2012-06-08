# encoding: utf-8
module CarrierWave
  module Workers

    class StoreAsset < Struct.new(:klass, :id, :column)

      if defined?(::Sidekiq)

        include ::Sidekiq::Worker
        def perform(klass, id, column)
          resource = klass.is_a?(String) ? klass.constantize : klass
          record = resource.find id
          if tmp = record.send(:"#{column}_tmp")
            asset = record.send(:"#{column}")
            cache_dir  = [asset.root, asset.cache_dir].join("/")
            cache_path = [cache_dir, tmp].join("/")
            tmp_dir = [cache_dir, tmp.split("/")[0]].join("/")
            record.send :"process_#{column}_upload=", true
            record.send :"#{column}_tmp=", nil
            File.open(cache_path) { |f| record.send :"#{column}=", f }
            if record.save!
              FileUtils.rm_r(tmp_dir, :force => true)
            end
          end
        end

      else

        @queue = :store_asset
        def self.perform(*args)
          new(*args).perform
        end
        def perform
          resource = klass.is_a?(String) ? klass.constantize : klass
          record = resource.find id
          if tmp = record.send(:"#{column}_tmp")
            asset = record.send(:"#{column}")
            cache_dir  = [asset.root, asset.cache_dir].join("/")
            cache_path = [cache_dir, tmp].join("/")
            tmp_dir = [cache_dir, tmp.split("/")[0]].join("/")
            record.send :"process_#{column}_upload=", true
            record.send :"#{column}_tmp=", nil
            File.open(cache_path) { |f| record.send :"#{column}=", f }
            if record.save!
              FileUtils.rm_r(tmp_dir, :force => true)
            end
          end
        end

      end
      
    end # StoreAsset
    
  end # Workers
end # Backgrounder

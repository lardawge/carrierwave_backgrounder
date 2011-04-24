module CarrierWave
  module Workers

    class StoreAsset < Struct.new(:klass, :id, :column)
  
      def perform
        record = klass.find id
        if tmp = record.send(:"#{column}_tmp")
          asset = record.send(:"#{column}")
          cache_dir  = [asset.root, asset.cache_dir].join("/")
          cache_path = [cache_dir, tmp].join("/")
        
          record.send :"process_#{column}_upload=", true
          record.send :"#{column}=", File.open(cache_path)
          record.send :"#{column}_tmp=", nil
          if record.save!
            FileUtils.rm(cache_path)
          end
        end
      end
      
    end # StoreAsset
    
  end # Workers
end # Backgrounder

module CarrierWave
  module Workers

    class StoreAsset < Struct.new(:klass, :id, :column)
  
      def perform
        record = klass.find id
        if record.send :"#{column}_tmp"
          cache_dir  = [record.send(:"#{column}").root, record.send(:"#{column}").cache_dir].join("/")
          cache_path = [cache_dir, record.send(:"#{column}_tmp")].join("/")
        
          record.send :"process_upload=", true
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
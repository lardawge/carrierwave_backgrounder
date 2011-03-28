module CarrierWave
  module Workers
      
    class StoreAsset < Struct.new(:klass, :id, :column, :options)
  
      def perform
        parent_id = (options) ? options.delete(:embedded_in_id) : nil
        record = if parent_id
                   # You can't access embedded records directory with Mongoid.
                   # So we jump through a few hoops...

                   # Find the parent record (tied to Rails/ActiveSupport right now)
                   parent = options[:embedded_in].to_s.classify.constantize.find parent_id
                   # Now find the actual record you want to process
                   parent.send(options[:inverse_of]).find id
                 else
                   klass.find id
                 end
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

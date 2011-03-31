module CarrierWave
  module Workers

    class ProcessAsset < Struct.new(:klass, :id, :column)
  
      def perform
        record = klass.find id
        record.process_upload = true
        record.send(:"#{column}").recreate_versions!
      end
      
    end # ProcessAsset
    
  end # Workers
end # Backgrounder

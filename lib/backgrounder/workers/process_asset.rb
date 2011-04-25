# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Struct.new(:klass, :id, :column)
  
      def perform
        record = klass.find id
        record.send(:"process_#{column}_upload=", true)
        if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
          record.update_attribute :"#{column}_processing", nil
        end
      end
      
    end # ProcessAsset
    
  end # Workers
end # Backgrounder

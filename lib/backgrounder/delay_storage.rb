module CarrierWave
  module Backgrounder

    module DelayStorage
      def cache_versions!(new_file)
        super(new_file) if proceed_with_versioning?
      end
      
      def proceed_with_versioning?
        !model.respond_to?(:process_upload) || model.process_upload
      end
    end # DelayStorage
    
  end # Backgrounder
end # CarrierWave
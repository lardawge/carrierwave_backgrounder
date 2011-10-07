module CarrierWave
  module Backgrounder

    module DelayStorage
      def cache_versions!(new_file)
        super(new_file) if proceed_with_versioning?
      end
      
      def proceed_with_versioning?
        !model.respond_to?(:"process_#{mounted_as}_upload") || model.send(:"process_#{mounted_as}_upload")
      end
    end # DelayStorage
    
  end # Backgrounder
end # CarrierWave
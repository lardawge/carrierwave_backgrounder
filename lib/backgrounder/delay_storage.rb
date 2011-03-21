module CarrierWave
  module Backgrounder

    module DelayStorage
      extend ActiveSupport::Concern
      
      included do
        send :carrierwave_uploader_overrides
      end
      
      module ClassMethods
 
        def carrierwave_uploader_overrides
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def cache_versions!(new_file)
              super(new_file) if proceed_with_versioning?
            end
          RUBY
        end
        
      end # ClassMethods
    end # DelayStorage
    
    def proceed_with_versioning?
      !model.respond_to?(:process_upload?) || model.process_upload?
    end
    
  end # Backgrounder
end # CarrierWave
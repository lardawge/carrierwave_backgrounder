require 'backgrounder/orm/activerecord'

module CarrierWave
  module Backgrounder

    module DelayedStorage
      extend ActiveSupport::Concern
      
      included do
        ::ActiveRecord::Base.send :include, ::CarrierWave::Backgrounder::ActiveRecord
        send :stub_version_caching!
      end
      
      module ClassMethods
 
        def stub_version_caching!
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def cache_versions!(new_file)
              super(new_file) if model.process_upload?
            end
          RUBY
        end
        
      end # ClassMethods
    end # DelayStorage
  
  end # Backgrounder
end # CarrierWave
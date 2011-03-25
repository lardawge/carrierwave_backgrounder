require 'backgrounder/workers/store_asset'

module CarrierWave
  module Backgrounder
    
    module ORM
      extend ActiveSupport::Concern

      module ClassMethods
        
        def store_in_background(column, version=false)
          send :after_save, :"enqueue_#{column}_storage"
          
          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_upload
            
            def write_#{column}_identifier
              super() and return if process_upload
              self.#{column}_tmp = _mounter(:#{column}).cache_name
            end
        
            def store_#{column}!
              super() if process_upload
            end
            
            def enqueue_#{column}_storage
              if !process_upload && #{column}_tmp
                ::Delayed::Job.enqueue ::CarrierWave::Workers::StoreAsset.new(self.class, id, #{column}.mounted_as)
              end
            end
          RUBY
        end
        
      end # ClassMethods
    end # ActiveRecord

  end #Backgrounder
end #CarrierWave
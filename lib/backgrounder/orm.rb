require 'backgrounder/workers/store_asset'

module CarrierWave
  module Backgrounder
    
    module ORM
      extend ActiveSupport::Concern

      module ClassMethods
        
        ##
        # class User < Activrecord::Base
        #   mount_uploader :avatar, AvatarUploader
        #   store_in_background :avatar
        # end
        # 
        # The above adds a #process_upload method to user.
        # What this allows is an override of pushing uploads
        # to a background process.
        # 
        def store_in_background(column, background_store=true, worker=::CarrierWave::Workers::StoreAsset)
          send :after_save, :"enqueue_#{column}_background_job"
          
          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_upload
            
            if background_store
              def write_#{column}_identifier
                super() and return if process_upload
                self.#{column}_tmp = _mounter(:#{column}).cache_name
              end
            
              def store_#{column}!
                super() if process_upload
              end
            end
            
            def enqueue_#{column}_background_job
              unless process_upload
                ::Delayed::Job.enqueue worker.new(self.class, id, #{column}.mounted_as)
              end
            end
          RUBY
        end
        
      end # ClassMethods
    end # ActiveRecord

  end #Backgrounder
end #CarrierWave

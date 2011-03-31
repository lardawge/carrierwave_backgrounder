require 'backgrounder/workers'

module CarrierWave
  module Backgrounder
    
    module ORM
      extend ActiveSupport::Concern

      module ClassMethods
        
        ##
        # #process_in_background will process and create versions for uploads in a background process.
        #
        # class User < ActiveRecord::Base
        #   mount_uploader :avatar, AvatarUploader
        #   process_in_background :avatar
        # end
        # 
        # The above adds a User#process_upload method which can be used at times when you want to bypass
        # background storage and processing.
        #   
        #   @user.process_upload = true
        #   @user.save
        #
        # You can also pass in your own workers using the second argument in case you need other things done
        # durring processing.
        #
        #   class User < ActiveRecord::Base
        #     mount_uploader :avatar, AvatarUploader
        #     process_in_background :avatar, CustomWorker
        #   end
        #
        def process_in_background(column, worker=::CarrierWave::Workers::ProcessAsset)
          send :after_save, :"enqueue_#{column}_background_job"
          
          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_upload
            
            def enqueue_#{column}_background_job
              unless process_upload
                ::Delayed::Job.enqueue #{worker}.new(self.class, id, #{column}.mounted_as)
              end
            end
          RUBY
        end

        ##
        # #store_in_background  will process, version and store uploads in a background process.
        #
        # class User < ActiveRecord::Base
        #   mount_uploader :avatar, AvatarUploader
        #   store_in_background :avatar
        # end
        # 
        # The above adds a User#process_upload method which can be used at times when you want to bypass
        # background storage and processing.
        #   
        #   @user.process_upload = true
        #   @user.save
        #
        # You can also pass in your own workers using the second argument in case you need other things done
        # durring processing.
        #
        #   class User < ActiveRecord::Base
        #     mount_uploader :avatar, AvatarUploader
        #     store_in_background :avatar, CustomWorker
        #   end
        #
        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          send :after_save, :"enqueue_#{column}_background_job"
          
          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_upload
            
            def write_#{column}_identifier
              super() and return if process_upload
              self.#{column}_tmp = _mounter(:#{column}).cache_name
            end
          
            def store_#{column}!
              super() if process_upload
            end
            
            def enqueue_#{column}_background_job
              unless process_upload
                ::Delayed::Job.enqueue #{worker}.new(self.class, id, #{column}.mounted_as)
              end
            end
          RUBY
        end
        
      end # ClassMethods
    end # ORM

  end #Backgrounder
end #CarrierWave

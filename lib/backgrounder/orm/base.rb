# encoding: utf-8
require 'backgrounder/workers'

module CarrierWave
  module Backgrounder
    module ORM

      ##
      # Base class for all things orm
      module Base

        ##
        # User#process_in_background will process and create versions in a background process.
        #
        # class User < ActiveRecord::Base
        #   mount_uploader :avatar, AvatarUploader
        #   process_in_background :avatar
        # end
        #
        # The above adds a User#process_upload method which can be used at times when you want to bypass
        # background storage and processing.
        #
        #   @user.process_avatar = true
        #   @user.save
        #
        # You can also pass in your own workers using the second argument in case you need other things done
        # during processing.
        #
        #   class User < ActiveRecord::Base
        #     mount_uploader :avatar, AvatarUploader
        #     process_in_background :avatar, CustomWorker
        #   end
        #
        # In addition you can also add a column to the database appended by _processing with a type of boolean
        # which can be used to check if processing is complete.
        #
        #   def self.up
        #     add_column :users, :avatar_processing, :boolean
        #   end
        #
        def process_in_background(column, worker=::CarrierWave::Workers::ProcessAsset)
          send :before_save, :"set_#{column}_processing", :if => :"trigger_#{column}_background_processing?"
          send :after_save,  :"enqueue_#{column}_background_job", :if => :"trigger_#{column}_background_processing?"

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_#{column}_upload

            def set_#{column}_processing
              self.#{column}_processing = true if respond_to?(:#{column}_processing)
            end

            def enqueue_#{column}_background_job
              if defined? ::Delayed::Job
                ::Delayed::Job.enqueue #{worker}.new(self.class.name, id, #{column}.mounted_as)
              elsif defined? ::Resque
                ::Resque.enqueue #{worker}, self.class.name, id, #{column}.mounted_as
              end
            end

            def trigger_#{column}_background_processing?
              process_#{column}_upload != true
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
        # The above adds a User#process_<column>_upload method which can be used at times when you want to bypass
        # background storage and processing.
        #
        #   @user.process_avatar_upload = true
        #   @user.save
        #
        # You can also pass in your own workers using the second argument in case you need other things done
        # during processing.
        #
        #   class User < ActiveRecord::Base
        #     mount_uploader :avatar, AvatarUploader
        #     store_in_background :avatar, CustomWorker
        #   end
        #
        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          send :after_save, :"enqueue_#{column}_background_job", :if => :"trigger_#{column}_background_storage?"

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_#{column}_upload

            def write_#{column}_identifier
              super() and return if process_#{column}_upload
              self.#{column}_tmp = _mounter(:#{column}).cache_name
            end

            def store_#{column}!
              super() if process_#{column}_upload
            end

            def enqueue_#{column}_background_job
              if defined? ::Delayed::Job
                ::Delayed::Job.enqueue #{worker}.new(self.class.name, id, #{column}.mounted_as)
              elsif defined? ::Resque
                ::Resque.enqueue #{worker}, self.class.name, id, #{column}.mounted_as
              end
            end

            def trigger_#{column}_background_storage?
              process_#{column}_upload != true
            end

          RUBY
        end

      end # Base

    end #ORM
  end #Backgrounder
end #CarrierWave

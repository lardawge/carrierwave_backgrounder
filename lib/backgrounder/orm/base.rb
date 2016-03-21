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
          attr_accessor :"process_#{column}_upload"

          mod = Module.new
          include mod

          _define_shared_backgrounder_methods(mod, column, worker)
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
          attr_accessor :"process_#{column}_upload"

          mod = Module.new
          include mod
          mod.class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def remove_#{column}=(value)
              super
              self.process_#{column}_upload = true
            end

            def write_#{column}_identifier
              super and return if process_#{column}_upload
              self.#{column}_tmp = #{column}_cache if #{column}_cache
            end

            def store_#{column}!
              super if process_#{column}_upload
            end

          RUBY

          _define_shared_backgrounder_methods(mod, column, worker)
        end

        private

        def _define_shared_backgrounder_methods(mod, column, worker)
          mod.class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def #{column}_updated?; true; end

            def set_#{column}_processing
              self.#{column}_processing = true if respond_to?(:#{column}_processing)
            end

            def enqueue_#{column}_background_job?
              !remove_#{column}? && !process_#{column}_upload && #{column}_updated?
            end

            def enqueue_#{column}_background_job
              CarrierWave::Backgrounder.enqueue_for_backend(#{worker}, self.class.name, id.to_s, #{column}.mounted_as)
            end
          RUBY
        end
      end # Base

    end #ORM
  end #Backgrounder
end #CarrierWave

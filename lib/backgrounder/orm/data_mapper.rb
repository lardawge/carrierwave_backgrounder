module CarrierWave
  module Backgrounder
    module ORM

      module DataMapper
        include CarrierWave::Backgrounder::ORM::Base

        def process_in_background(column, worker=::CarrierWave::Workers::ProcessAsset)
          before :save, :"set_#{column}_processing"
          after  :save, :"enqueue_#{column}_background_job"

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_#{column}_upload
            attr_reader :#{column}_changed

            def set_#{column}_processing
              @#{column}_changed = attribute_dirty?(:#{column})
              self.#{column}_processing = true if respond_to?(:#{column}_processing) 
            end

            def enqueue_#{column}_background_job
              if trigger_#{column}_background_processing?
                CarrierWave::Backgrounder.enqueue_for_backend(#{worker}, self.class.name, id, #{column}.mounted_as)
                @#{column}_changed = false
              end
            end

            def trigger_#{column}_background_processing?
              process_#{column}_upload != true && #{column}_changed
            end

          RUBY
        end

        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          before :save, :"set_#{column}_changed"
          after :save, :"enqueue_#{column}_background_job"

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_#{column}_upload
            attr_reader :#{column}_changed

            def set_#{column}_changed
              @#{column}_changed = attribute_dirty?(:#{column})
            end

            def write_#{column}_identifier
              super() and return if process_#{column}_upload
              self.#{column}_tmp = _mounter(:#{column}).cache_name
            end

            def store_#{column}!
              super() if process_#{column}_upload
            end

            def enqueue_#{column}_background_job
              if trigger_#{column}_background_storage?
                CarrierWave::Backgrounder.enqueue_for_backend(#{worker}, self.class.name, id, #{column}.mounted_as)
                @#{column}_changed = false
              end
            end

            def trigger_#{column}_background_storage?
              process_#{column}_upload != true && #{column}_changed
            end

          RUBY
        end
      end # DataMapper

    end #ORM
  end #Backgrounder
end #CarrierWave

DataMapper::Model.append_extensions ::CarrierWave::Backgrounder::ORM::DataMapper

module CarrierWave
  module Backgrounder
    module ORM

      module DataMapper
        include CarrierWave::Backgrounder::ORM::Base

        def process_in_background(column, worker=::CarrierWave::Workers::ProcessAsset)
          send :before, :save, :"set_#{column}_processing"
          send :after,  :save, :"enqueue_#{column}_background_job"

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_accessor :process_#{column}_upload

            def set_#{column}_processing
              unless trigger_#{column}_background_processing?
                self.#{column}_processing = true if respond_to?(:#{column}_processing) 
              end
            end

            def enqueue_#{column}_background_job
              unless trigger_#{column}_background_processing?
                ::Delayed::Job.enqueue #{worker}.new(self.class, id, #{column}.mounted_as) 
              end
            end

            def trigger_#{column}_background_processing?
              process_#{column}_upload != true && attribute_dirty?(:#{column})
            end

          RUBY
        end

        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          send :after, :save, :"enqueue_#{column}_background_job"

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
              unless trigger_#{column}_background_storage?
                ::Delayed::Job.enqueue #{worker}.new(self.class, id, #{column}.mounted_as) 
              end
            end

            def trigger_#{column}_background_storage?
              process_#{column}_upload != true && attribute_dirty?(:#{column})
            end

          RUBY
        end
      end # DataMapper

    end #ORM
  end #Backgrounder
end #CarrierWave

DataMapper::Model.append_extensions ::CarrierWave::Backgrounder::ORM::DataMapper

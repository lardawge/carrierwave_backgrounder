module CarrierWave
  module Backgrounder
    module ORM

      module DataMapper
        include CarrierWave::Backgrounder::ORM::Base

        def process_in_background(column, worker=::CarrierWave::Workers::ProcessAsset)
          super

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def set_#{column}_processing
              @#{column}_changed = attribute_dirty?(:#{column})
              self.#{column}_processing = true if respond_to?(:#{column}_processing)
            end
          RUBY
        end

        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          super

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def set_#{column}_changed
              @#{column}_changed = attribute_dirty?(:#{column})
            end

            def write_#{column}_identifier
              super and return if process_#{column}_upload
              self.#{column}_tmp = #{column}_cache
            end
          RUBY
        end

        private

        def _define_shared_backgrounder_methods(mod, column, worker)
          before :save, :"set_#{column}_changed"
          after  :save, :"enqueue_#{column}_background_job"

          super

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            attr_reader :#{column}_changed

            def enqueue_#{column}_background_job
              if enqueue_#{column}_background_job?
                CarrierWave::Backgrounder.enqueue_for_backend(#{worker}, self.class.name, id, #{column}.mounted_as)
                @#{column}_changed = false
              end
            end

            def #{column}_updated?
              #{column}_changed
            end
          RUBY
        end
      end # DataMapper

    end #ORM
  end #Backgrounder
end #CarrierWave

DataMapper::Model.append_extensions ::CarrierWave::Backgrounder::ORM::DataMapper

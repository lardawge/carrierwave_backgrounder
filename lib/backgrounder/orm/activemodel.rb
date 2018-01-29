module CarrierWave
  module Backgrounder
    module ORM
      module ActiveModel
        include CarrierWave::Backgrounder::ORM::Base

        private

        def _define_shared_backgrounder_methods(mod, column, worker)
          before_save :"set_#{column}_processing",
                      if: :"enqueue_#{column}_background_job?"
          send _supported_callback, :"enqueue_#{column}_background_job",
               if: :"enqueue_#{column}_background_job?"

          super

          define_method :"#{column}_updated?" do
            options = self.class.uploader_options[column] || {}
            serialization_column = options[:mount_on] || column

            send(:"#{serialization_column}_changed?") ||
              previous_changes.key?(:"#{serialization_column}") ||
              send(:"remote_#{column}_url").present? ||
              send(:"#{column}_cache").present?
          end
        end

        def _supported_callback
          return :after_commit if respond_to?(:after_commit)
          :after_save
        end
      end
    end
  end
end

# encoding: utf-8

module CarrierWave
  module Backgrounder
    module ORM

      module ActiveModel
        include CarrierWave::Backgrounder::ORM::Base

        private

        def _define_shared_backgrounder_methods(mod, column, worker, callback)
          before_save :"set_#{column}_processing", :if => :"enqueue_#{column}_background_job?"
          send _supported_callback, :"enqueue_#{column}_background_job", :if => :"enqueue_#{column}_background_job?"

          super

          define_method :"#{column}_updated?" do
            options = self.class.uploader_options[column] || {}
            serialization_column = options[:mount_on] || column

            send(:"#{serialization_column}_changed?") ||              # after_save support
            previous_changes.has_key?(:"#{serialization_column}") ||  # after_commit support
            send(:"remote_#{column}_url").present? ||                 # Remote upload support
            send(:"#{column}_cache").present?                         # Form failure support
          end
        end

        def _supported_callback
          respond_to?(:after_commit) ? :after_commit : :after_save
        end
      end # ActiveModel

    end # ORM
  end # Backgrounder
end # CarrierWave

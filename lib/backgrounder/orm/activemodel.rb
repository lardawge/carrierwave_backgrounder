# encoding: utf-8

module CarrierWave
  module Backgrounder
    module ORM

      module ActiveModel
        include CarrierWave::Backgrounder::ORM::Base

        def process_in_background(column, worker=::CarrierWave::Workers::ProcessAsset)
          before_save :"set_#{column}_processing", :if => :"enqueue_#{column}_background_job?"
          send _supported_am_after_callback, :"enqueue_#{column}_background_job", :if => :"enqueue_#{column}_background_job?"
          super
        end

        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          send _supported_am_after_callback, :"enqueue_#{column}_background_job", :if => :"enqueue_#{column}_background_job?"
          super
        end

        private

        def _supported_am_after_callback
          respond_to?(:after_commit) ? :after_commit : :after_save
        end

        def _define_shared_backgrounder_methods(mod, column, worker)
          super

          define_method :"#{column}_updated?" do
            send(:"#{column}_changed?") ||              # after_save support
            previous_changes.has_key?(:"#{column}") ||  # after_commit support
            send(:"remote_#{column}_url").present? ||   # Remote upload support
            send(:"#{column}_cache").present?           # Form failure support
          end
        end
      end # ActiveModel

    end # ORM
  end # Backgrounder
end # CarrierWave


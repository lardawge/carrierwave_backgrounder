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

          __define_shared(column)
        end

        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          send _supported_am_after_callback, :"enqueue_#{column}_background_job", :if => :"enqueue_#{column}_background_job?"
          super

          __define_shared(column)
        end

        private

        def _supported_am_after_callback
          respond_to?(:after_commit) ? :after_commit : :after_save
        end

        def __define_shared(column)
          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def #{column}_updated?
              #{column}_changed? ||                     # after_save support
              previous_changes.has_key?(:#{column}) ||  # after_commit support
              remote_#{column}_url.present? ||          # Remote upload support
              #{column}_cache.present?                  # Form failure support
            end
          RUBY
        end
      end # ActiveModel

    end # ORM
  end # Backgrounder
end # CarrierWave


# encoding: utf-8

module CarrierWave
  module Backgrounder
    module ORM

      module ActiveModel
        include CarrierWave::Backgrounder::ORM::Base

        def process_in_background(column, worker=::CarrierWave::Workers::ProcessAsset)
          super

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def enqueue_#{column}_background_job?
              super &&
              (#{column}_changed? || previous_changes.has_key?(:#{column}) || remote_#{column}_url.present? || #{column}_cache.present?)
            end
          RUBY
        end

        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          super

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def enqueue_#{column}_background_job?
              super &&
              (#{column}_changed? || previous_changes.has_key?(:#{column}) || remote_#{column}_url.present? || #{column}_cache.present?)
            end
          RUBY
        end
      end # ActiveModel

    end # ORM
  end # Backgrounder
end # CarrierWave


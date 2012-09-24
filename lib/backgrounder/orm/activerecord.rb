# encoding: utf-8
require 'active_record'

module CarrierWave
  module Backgrounder
    module ORM

      module ActiveRecord
        include CarrierWave::Backgrounder::ORM::Base

        def process_in_background(column, worker=::CarrierWave::Workers::ProcessAsset)
          super

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def trigger_#{column}_background_processing?
              super && (#{column}_changed? || remote_#{column}_url.present?)
            end
          RUBY
        end

        def store_in_background(column, worker=::CarrierWave::Workers::StoreAsset)
          super

          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def trigger_#{column}_background_storage?
              super && (#{column}_changed? || remote_#{column}_url.present?)
            end
          RUBY
        end
      end # ActiveRecord

    end # ORM
  end # Backgrounder
end # CarrierWave

ActiveRecord::Base.extend CarrierWave::Backgrounder::ORM::ActiveRecord

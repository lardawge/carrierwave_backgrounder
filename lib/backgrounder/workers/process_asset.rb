# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Struct.new(:klass, :id, :column)

      if defined?(::Sidekiq)
        include ::Sidekiq::Worker
        def perform(klass, id, column)
          resource = klass.is_a?(String) ? klass.constantize : klass
          record = resource.find id

          if record
            record.send(:"process_#{column}_upload=", true)
            if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
              record.update_attribute :"#{column}_processing", nil
            end
          end
        end
      else
        @queue = :process_asset
        def self.perform(*args)
          new(*args).perform
        end
        def perform
          resource = klass.is_a?(String) ? klass.constantize : klass
          record = resource.find id

          if record
            record.send(:"process_#{column}_upload=", true)
            if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
              record.update_attribute :"#{column}_processing", nil
            end
          end
        end
      end

    end # ProcessAsset

  end # Workers
end # Backgrounder

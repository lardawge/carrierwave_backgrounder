# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Struct.new(:klass, :id, :column)

      if defined?(::Sidekiq)
        include ::Sidekiq::Worker
      end

      def self.perform(*args)
        new(*args).perform
      end

      def perform(*args)
        set_args(*args) unless args.empty?
        resource = klass.is_a?(String) ? klass.constantize : klass
        record = resource.find id

        if record
          record.send(:"process_#{column}_upload=", true)
          if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
            record.send :"#{column}_processing=", nil
            record.save!
          end
        end
      end

      def set_args(klass, id, column)
        self.klass, self.id, self.column = klass, id, column
      end

    end # ProcessAsset

  end # Workers
end # Backgrounder

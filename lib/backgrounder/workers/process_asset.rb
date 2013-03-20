# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Struct.new(:klass, :id, :column)
      def self.perform(*args)
        new(*args).perform
      end

      def perform(*args)
        set_args(*args) if args.present?

        errors = []
        errors << ::ActiveRecord::RecordNotFound      if defined?(::ActiveRecord)
        errors << ::Mongoid::Errors::DocumentNotFound if defined?(::Mongoid)

        record = begin
          constantized_resource.find(id)
        rescue *errors
          nil
        end

        if record
          record.send(:"process_#{column}_upload=", true)
          if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
            record.update_attribute :"#{column}_processing", nil
          end
        end
      end

      private

      def set_args(klass, id, column)
        self.klass, self.id, self.column = klass, id, column
      end

      def constantized_resource
        klass.is_a?(String) ? klass.constantize : klass
      end

    end # ProcessAsset

  end # Workers
end # Backgrounder

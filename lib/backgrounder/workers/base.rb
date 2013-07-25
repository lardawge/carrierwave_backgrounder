module CarrierWave
  module Workers
    class Base < Struct.new(:klass, :id, :column)

      def self.perform(*args)
        new(*args).perform
      end

      def perform(*args)
        set_args(*args) if args.present?
        constantized_resource.find id
      rescue *not_found_errors
      end

      private

      def not_found_errors
        [].tap do |errors|
          errors << ::ActiveRecord::RecordNotFound      if defined?(::ActiveRecord)
          errors << ::Mongoid::Errors::DocumentNotFound if defined?(::Mongoid)
        end
      end

      def set_args(klass, id, column)
        self.klass, self.id, self.column = klass, id, column
      end

      def constantized_resource
        klass.is_a?(String) ? klass.constantize : klass
      end

    end
  end
end

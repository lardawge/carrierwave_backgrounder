# encoding: utf-8
module CarrierWave
  module Workers

    module Base
      attr_accessor :klass, :id, :column, :record

      def initialize(*args)
        super(*args) unless self.class.superclass == Object
        set_args(*args) if args.present?
      end

      def perform(*args)
        set_args(*args) if args.present?
        self.record = constantized_resource.find id
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

      def when_not_ready
      end

    end # Base

  end # Workers
end # CarrierWave

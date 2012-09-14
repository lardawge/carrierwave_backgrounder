# encoding: utf-8
module CarrierWave
  module Workers

    class ProcessAsset < Struct.new(:klass, :id, :column)
      include ::Sidekiq::Worker if defined?(::Sidekiq)
      @queue = :process_asset

      def self.perform(*args)
        new(*args).perform
      end

      def perform(*args)
        set_args(*args) unless args.empty?
        resource = klass.is_a?(String) ? klass.constantize : klass
        @record = resource.find id

        if @record
          @record.send(:"process_#{column}_upload=", true)
          if @record.send(:"#{column}").recreate_versions! && @record.respond_to?(:"#{column}_processing")
            @record.send :"#{column}_processing=", nil
            @record.save!
          end
        end
      end

      def set_args(klass, id, column)
        self.klass, self.id, self.column = klass, id, column
      end

      def enqueue(job)
        if @record.respond_to?(:enqueue_callback)
          @record.enqueue_callback(job)
        end
      end

      def before(job)
        if @record.respond_to?(:before_callback)
          @record.before_callback(job)
        end
      end

      def after(job)
        if @record.respond_to?(:after_callback)
          @record.after_callback(job)
        end
      end

      def success(job)
        if @record.respond_to?(:success_callback)
          @record.success_callback(job)
        end
      end

      def error(job, exception)
        if @record.respond_to?(:error_callback)
          @record.error_callback(job, exception)
        end
      end

      def failure
        if @record.respond_to?(:failure_callback)
          @record.failure_callback
        end
      end

    end # ProcessAsset

  end # Workers
end # Backgrounder

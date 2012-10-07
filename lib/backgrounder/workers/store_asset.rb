# encoding: utf-8
module CarrierWave
  module Workers

    class StoreAsset < Struct.new(:klass, :id, :column)
      include ::Sidekiq::Worker if defined?(::Sidekiq)
      @queue = :store_asset

      def self.perform(*args)
        new(*args).perform
      end

      def perform(*args)
        set_args(*args) unless args.empty?
        resource = klass.is_a?(String) ? klass.constantize : klass
        @record = resource.find id
        
        if tmp = @record.send(:"#{column}_tmp")
          asset = @record.send(:"#{column}")
          cache_dir  = [asset.root, asset.cache_dir].join("/")
          cache_path = [cache_dir, tmp].join("/")
          tmp_dir = [cache_dir, tmp.split("/")[0]].join("/")
          @record.send :"process_#{column}_upload=", true
          @record.send :"#{column}_tmp=", nil
          File.open(cache_path) { |f| @record.send :"#{column}=", f }
          if @record.save!
            FileUtils.rm_r(tmp_dir, :force => true)
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

    end # StoreAsset
    
  end # Workers
end # Backgrounder

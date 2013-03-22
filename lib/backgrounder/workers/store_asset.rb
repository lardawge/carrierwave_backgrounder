# encoding: utf-8
module CarrierWave
  module Workers

    class StoreAsset < Struct.new(:klass, :id, :column)
      attr_reader :cache_path, :tmp_directory

      def self.perform(*args)
        new(*args).perform
      end

      def perform(*args)
        if defined?(::ActiveRecord) and defined(::SuckerPunch)
          # check if we have checked out a connection for this job
          if args.last == :ar_connection_pool
            # ok, we have the connection, proceed with the job
            # removing the connection flag
            args.pop
          else
            # we cannot find the flag, so let's add an additional parameter
            # to signal that the connection is being checked out
            args << :ar_connection_pool
            # and perform again with the new flag added.
            return ::ActiveRecord::Base.connection_pool.with_connection do
              perform(*args)
            end
          end
        end

        set_args(*args) if args.present?

        errors = []
        errors << ::ActiveRecord::RecordNotFound      if defined?(::ActiveRecord)
        errors << ::Mongoid::Errors::DocumentNotFound if defined?(::Mongoid)

        record = begin
          constantized_resource.find(id)
        rescue *errors
          nil
        end

        if record && record.send(:"#{column}_tmp")
          store_directories(record)
          record.send :"process_#{column}_upload=", true
          record.send :"#{column}_tmp=", nil
          File.open(cache_path) { |f| record.send :"#{column}=", f }
          if record.save!
            FileUtils.rm_r(tmp_directory, :force => true)
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

      def store_directories(record)
        asset, asset_tmp = record.send(:"#{column}"), record.send(:"#{column}_tmp")
        cache_directory  = File.expand_path(asset.cache_dir, asset.root)
        @cache_path      = File.join(cache_directory, asset_tmp)
        @tmp_directory   = File.join(cache_directory, asset_tmp.split("/").first)
      end
    end # StoreAsset

  end # Workers
end # Backgrounder

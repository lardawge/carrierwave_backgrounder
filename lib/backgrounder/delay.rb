module CarrierWave
  module Backgrounder

    module Delay
      def cache_versions!(new_file)
        super if proceed_with_versioning?
      end

      def store_versions!(*args)
        super if proceed_with_versioning?
      end

      def process!(new_file=nil)
        super if proceed_with_versioning?
      end

      private

      def proceed_with_versioning?
        enable_processing && bypass_backgrounding?
      end

      def bypass_backgrounding?
        if model.respond_to?(:"process_#{mounted_as}_upload")
          !!model.send(:"process_#{mounted_as}_upload")
        else
          true
        end
      end
    end # Delay

  end # Backgrounder
end # CarrierWave

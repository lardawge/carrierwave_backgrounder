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
        if !model.respond_to?(:"process_#{mounted_as}_upload")
          return enable_processing
        else
          return !!(model.send(:"process_#{mounted_as}_upload") && enable_processing)
        end

        false
      end
    end # Delay

  end # Backgrounder
end # CarrierWave

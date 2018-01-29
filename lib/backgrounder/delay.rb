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
        !model.respond_to?(:"process_#{mounted_as}_upload") && enable_processing ||
          !!(model.send(:"process_#{mounted_as}_upload") && enable_processing)
      end
    end
  end
end

module CarrierWave
  module Backgrounder

    module Delay

      ##
      # Intercept carrierwave#cache_versions! so we can process versions later.
      def cache_versions!(new_file)
        super(new_file) if proceed_with_versioning?
      end

      def process!(new_file=nil)
        super(new_file) if proceed_with_versioning?
      end
      
      private

      def proceed_with_versioning?
        !model.respond_to?(:"process_#{mounted_as}_upload") || model.send(:"process_#{mounted_as}_upload")
      end
    end # Delay
    
  end # Backgrounder
end # CarrierWave

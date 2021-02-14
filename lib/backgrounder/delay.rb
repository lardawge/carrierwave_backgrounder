require 'active_support/concern'

module CarrierWave
  module Backgrounder

    module Delay
      extend ActiveSupport::Concern

      included do
        class_attribute :selective_processing, instance_writer: false
        self.selective_processing = false
      end

      def cache_versions!(new_file)
        super if proceed_with_versioning?
      end

      def store_versions!(*args)
        super if proceed_with_versioning?
      end

      def process!(new_file=nil)
        super if proceed_with_versioning?
      end

      def processing_delayed?(img = nil)
        model.respond_to?(:"processing_#{mounted_as}_delayed") &&
          model.send(:"processing_#{mounted_as}_delayed")
      end

      def processing_immediate?(img = nil)
        !processing_delayed?(img)
      end

      module ClassMethods
        def selective_processing!
          self.selective_processing = true
        end
      end # ClassMethods

      private

      def proceed_with_versioning?
        self.class.selective_processing ||
          !model.respond_to?(:"process_#{mounted_as}_upload") && enable_processing ||
          !!(model.send(:"process_#{mounted_as}_upload") && enable_processing)
      end
    end # Delay

  end # Backgrounder
end # CarrierWave

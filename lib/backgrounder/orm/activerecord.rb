require 'backgrounder/workers/store_asset'

module CarrierWave
  module Backgrounder
    
    module ActiveRecord
      extend ActiveSupport::Concern

      module ClassMethods
        
        def store_in_background(column)
          after_save :enqueue_background_store
          
          class_eval  <<-RUBY, __FILE__, __LINE__ + 1
            def write_#{column}_identifier
              super() and return if process_upload?
              self.#{column}_tmp = _mounter(:#{column}).cache_name
            end
        
            def store_#{column}!
              super() if process_upload?
            end
          RUBY
        end
        
      end # ClassMethods
      
      attr_accessor :process_upload
      alias_method  :process_upload?, :process_upload
      
      private
      
      def enqueue_background_store
        self.class.uploaders.keys.each do |column|
          if respond_to?(:"#{column}_tmp") && send(:"#{column}_tmp")
            ::Delayed::Job.enqueue ::CarrierWave::Workers::StoreAsset.new(self.class, id, column)
          end
        end
      end
      
    end # ActiveRecord

  end #Backgrounder
end #CarrierWave
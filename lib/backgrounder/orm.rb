require 'backgrounder/workers/store_asset'

module CarrierWave
  module Backgrounder
    
    module ORM
      extend ActiveSupport::Concern

      module ClassMethods
        
        def store_in_background(column, version=false, options={})
          send :after_save, :"enqueue_#{column}_storage"

          class_eval  do
            attr_accessor :process_upload
            
            define_method :"write_#{column}_identifier" do
              super() and return if process_upload
              self.send(:"#{column}_tmp=", _mounter(column).cache_name)
            end
        
            define_method :"store_#{column}!" do
              super() if process_upload
            end
            
            define_method :"enqueue_#{column}_storage" do
              options.merge!(:embedded_in_id => self.send(options[:embedded_in]).id) if options[:embedded_in]
              if !process_upload && send(:"#{column}_tmp")
                ::Delayed::Job.enqueue ::CarrierWave::Workers::StoreAsset.new(self.class, id, send(column).mounted_as, options)
              end
            end
          end
        end
        
      end # ClassMethods
    end # ORM

  end #Backgrounder
end #CarrierWave

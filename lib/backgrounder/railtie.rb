module CarrierWave
  module Backgrounder
    class Railtie < Rails::Railtie

      initializer "carrierwave_backgrounder.active_record" do
        ActiveSupport.on_load :active_record do
          require 'backgrounder/orm/activemodel'
          ::ActiveRecord::Base.extend CarrierWave::Backgrounder::ORM::ActiveModel
        end
      end

      initializer "carrierwave_backgrounder.data_mapper", :before =>"data_mapper.add_to_prepare" do
        require 'backgrounder/orm/data_mapper' if defined?(DataMapper)
      end

      initializer "carrierwave_backgrounder.mongoid" do
        if defined?(::Mongoid)
          require 'backgrounder/orm/activemodel'
          ::Mongoid::Document::ClassMethods.send(:include, ::CarrierWave::Backgrounder::ORM::ActiveModel)
        end
      end

    end
  end
end

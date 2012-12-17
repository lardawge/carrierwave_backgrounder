require 'active_support/core_ext/object'
require 'backgrounder/support/backends'
require 'backgrounder/orm/base'
require 'backgrounder/delay'

module CarrierWave
  module Backgrounder
    include Support::Backends

    class UnsupportedBackendError < StandardError ; end
    class ToManyBackendsAvailableError < StandardError ; end

    def self.configure
      yield self
    end

  end
end

if defined?(Rails)
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
          if defined?(Mongoid)
            require 'backgrounder/orm/activemodel'
            ::Mongoid::Document::ClassMethods.send(:include, ::CarrierWave::Backgrounder::ORM::ActiveModel)
          end
        end

      end
    end
  end
end

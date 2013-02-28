require 'active_support/core_ext/object'
require 'backgrounder/support/backends'
require 'backgrounder/orm/base'
require 'backgrounder/delay'

module CarrierWave
  module Backgrounder
    include Support::Backends

    class UnsupportedBackendError < StandardError ; end
    class TooManyBackendsAvailableError < StandardError ; end

    def self.configure
      yield self
      if @backend == :sidekiq
        ::CarrierWave::Workers::ProcessAsset.class_eval do
          require 'sidekiq'
          include ::Sidekiq::Worker
        end
        ::CarrierWave::Workers::StoreAsset.class_eval do
          require 'sidekiq'
          include ::Sidekiq::Worker
        end
      end
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
            require 'backgrounder/orm/activemodel_test' if Rails.env.test?
            ::ActiveRecord::Base.extend CarrierWave::Backgrounder::ORM::ActiveModel
          end
        end

        initializer "carrierwave_backgrounder.data_mapper", :before =>"data_mapper.add_to_prepare" do
          if defined?(DataMapper)
            require 'backgrounder/orm/data_mapper'
            require 'backgrounder/orm/data_mapper_test' if Rails.env.test?
          end
        end

        initializer "carrierwave_backgrounder.mongoid" do
          if defined?(Mongoid)
            require 'backgrounder/orm/activemodel'
            require 'backgrounder/orm/activemodel_test' if Rails.env.test?
            ::Mongoid::Document::ClassMethods.send(:include, ::CarrierWave::Backgrounder::ORM::ActiveModel)
          end
        end

      end
    end
  end
end

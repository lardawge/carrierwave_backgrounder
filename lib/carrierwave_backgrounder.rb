require 'active_support/core_ext/object'
require 'backgrounder/support/backends'
require 'backgrounder/orm/base'
require 'backgrounder/delay'

module CarrierWave
  module Backgrounder
    include Support::Backends

    def self.configure
      yield self
      case @backend
      when :sidekiq
        require 'sidekiq'
        ::CarrierWave::Workers::ProcessAsset.class_eval do
          include ::Sidekiq::Worker
        end
        ::CarrierWave::Workers::StoreAsset.class_eval do
          include ::Sidekiq::Worker
        end
      when :sucker_punch
        require 'sucker_punch'
        ::CarrierWave::Workers::ProcessAsset.class_eval do
          include ::SuckerPunch::Job
        end
        ::CarrierWave::Workers::StoreAsset.class_eval do
          include ::SuckerPunch::Job
        end
      end
    end

  end
end

require 'backgrounder/railtie' if defined?(Rails)

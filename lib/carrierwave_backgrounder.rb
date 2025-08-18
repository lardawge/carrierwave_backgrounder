require 'fileutils'
require 'active_support/core_ext/object'
require 'backgrounder/support/backends'
require 'backgrounder/orm/base'
require 'backgrounder/delay'

module CarrierWave
  module Backgrounder
    include Support::Backends

    class << self
      attr_reader :worker_klass, :suppress_not_found_errors
    end

    def self.configure
      yield self

      @suppress_not_found_errors ||= true

      case backend
      when :active_job
        @worker_klass = 'CarrierWave::Workers::ActiveJob'
        require 'backgrounder/workers/active_job/process_asset'
        require 'backgrounder/workers/active_job/store_asset'

        queue_name = queue_options[:queue] || 'carrierwave'

        ::CarrierWave::Workers::ActiveJob::ProcessAsset.class_eval do
          queue_as queue_name
        end
        ::CarrierWave::Workers::ActiveJob::StoreAsset.class_eval do
          queue_as queue_name
        end
      when :sidekiq
        @worker_klass = 'CarrierWave::Workers'

        ::CarrierWave::Workers::ProcessAsset.class_eval do
          include ::Sidekiq::Worker
        end
        ::CarrierWave::Workers::StoreAsset.class_eval do
          include ::Sidekiq::Worker
        end
      end
    end

    def self.suppress_record_not_found_errors(surpress_errors = true)
      @suppress_not_found_errors = surpress_errors
    end
  end
end

require 'backgrounder/railtie' if defined?(Rails)

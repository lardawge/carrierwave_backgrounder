# Fixture module declarations for backend detection testing

module GirlFriday
  class WorkQueue
  end
end

module Delayed
  class Job
    def self.column_names
      %w(id priority attempts handler queue last_error run_at locked_at failed_at locked_by created_at updated_at)
    end

    column_names.each do |column_name|
      define_method(column_name) { nil }
    end
  end
end

module Resque
end

module Qu
end

module Sidekiq
  module Client
  end

  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Sidekiq::Worker#sidekiq_options returns nil instead of the options hash
      # since 7e094567a585578fad0bfd0c8669efb46643f853
      def sidekiq_options(opts = {})
        @opts = opts
        nil
      end

      def get_sidekiq_options
        @opts || {}
      end

      def client_push(item)
      end
    end
  end
end

module QC
end

module SuckerPunch
  class Queue
  end
end

module Rails
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end

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
      def sidekiq_options(opts = {})
        opts
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

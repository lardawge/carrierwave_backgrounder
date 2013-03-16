# Fixture module declarations for backend detection testing

module GirlFriday
  class WorkQueue
  end
end

module Delayed
  module Job
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

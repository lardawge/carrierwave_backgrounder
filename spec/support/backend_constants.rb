# Fixture module declarations for backend detection testing

module GirlFriday
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
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def sidekiq_options(opts = {})
      end
    end
  end
end

module QC
end

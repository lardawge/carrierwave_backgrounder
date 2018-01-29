module CarrierWave
  module Workers
    module ClassMethods
      def perform(*args)
        new(*args).perform
      end
    end
  end
end

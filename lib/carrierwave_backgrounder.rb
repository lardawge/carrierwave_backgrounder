module CarrierWave
  module Backgrounder
    autoload :DelayStorage, 'backgrounder/delay_storage'

    module ORM
      autoload :Base, 'backgrounder/orm/base'
    end
  end
end

if defined?(Rails)
  module CarrierWave
    module Backgrounder
      class Railtie < Rails::Railtie

        initializer "carrierwave_backgrounder.active_record" do
          ActiveSupport.on_load :active_record do
            require 'backgrounder/orm/activerecord'
          end
        end

        initializer "carrierwave_backgrounder.data_mapper", :before =>"data_mapper.add_to_prepare" do
          require 'backgrounder/orm/data_mapper'
        end

      end
    end
  end
end

if defined?(GirlFriday)
  require 'girl_friday'

  CARRIERWAVE_QUEUE = GirlFriday::WorkQueue.new(:carrierwave) do |msg|
    worker = msg[:worker]
    worker.perform
  end
end

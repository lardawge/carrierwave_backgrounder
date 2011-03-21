module CarrierWave
  module Backgrounder
    autoload :DelayStorage, 'backgrounder/delay_storage'
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
      end
    end
  end
end
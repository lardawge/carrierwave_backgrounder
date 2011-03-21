module CarrierWave
  module Backgrounder
    autoload :DelayStorage, 'backgrounder/delay_storage'
    autoload :ORM,          'backgrounder/orm'
  end
end

if defined?(Rails)
  module CarrierWave
    module Backgrounder
      class Railtie < Rails::Railtie
        initializer "carrierwave_backgrounder.active_record" do
          ActiveSupport.on_load :active_record do
            ::ActiveRecord::Base.send :include, ::CarrierWave::Backgrounder::ORM
          end
        end
      end
    end
  end
end
module CarrierwaveBackgrounder
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def copy_config
        template "config/initializers/carrierwave_backgrounder.rb"
      end

      def info_config
        puts <<-EOF

        \e[33mBy default :delayed_job is used as the backend for carrierwave_backgrounder with :carrierwave as the queue name.
        To change this, edit config/initializers/carrierwave_backgrounder.rb.\e[0m

        EOF
      end
    end
  end
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require_relative 'support/dummy_app/config/environment'
require 'rspec/rails'
require 'backgrounder/railtie'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.before do
    CarrierWave::Backgrounder::Railtie.initializers.each(&:run)
  end

  config.after(:example, images: true) do
    FileUtils.rm_rf Dir.glob("spec/support/dummy_app/tmp/images/*")
  end
end

ActiveRecord::Schema.verbose = false
load 'support/dummy_app/db/schema.rb' # use db agnostic schema by default

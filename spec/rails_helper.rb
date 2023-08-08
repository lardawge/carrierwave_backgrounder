require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require_relative 'support/dummy_app/config/environment'
require_relative 'support/global_macros'
require 'sidekiq/testing'
require 'rspec/rails'
require 'backgrounder/railtie'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.include GlobalMacros

  config.after(:example, clear_images: true) do
    Sidekiq::Queues.clear_all
    FileUtils.rm_rf Dir.glob("spec/support/dummy_app/tmp/images/*")
    FileUtils.rm_rf Dir.glob("spec/support/dummy_app/public/uploads/*")
  end
end

ActiveRecord::Schema.verbose = false
load 'support/dummy_app/db/schema.rb' # use db agnostic schema by default

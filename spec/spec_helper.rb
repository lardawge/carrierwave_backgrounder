# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'pry'
require 'rails'
require 'carrierwave_backgrounder'

module WarningSuppression
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

RSpec.configure do |c|
  c.include WarningSuppression

  if ENV['BACKEND'] == 'active_job'
    c.exclude_pattern = '**/integrations/sidekiq/*'
  elsif ENV['BACKEND'] == 'sidekiq'
    c.exclude_pattern = '**/integrations/active_job/*'
  end
end

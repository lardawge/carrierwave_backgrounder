# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'logger'
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
  c.mock_with :mocha
  c.include WarningSuppression
end


# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'support/backend_constants'
require 'logger'

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


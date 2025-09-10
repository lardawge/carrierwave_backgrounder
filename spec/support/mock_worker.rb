require 'sidekiq'

class MockWorker < Struct.new(:klass, :id, :column)
  def self.perform(*args)
    new(*args).perform
  end

  def perform(*args)
    set_args(*args) unless args.empty?
  end

  def set_args(klass, id, column)
    self.klass, self.id, self.column = klass, id, column
  end
end

class MockSidekiqWorker < MockWorker
  include Sidekiq::Worker
end

class MockNamedSidekiqWorker < MockWorker
  include Sidekiq::Worker
  sidekiq_options queue: :even_better_name
end

class MockActiveJob
  def self.set(options = {})
    self
  end

  def self.perform_later(*args)
  end

  def self.queue_name
    'carrierwave'
  end
end

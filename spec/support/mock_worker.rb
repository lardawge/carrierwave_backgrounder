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

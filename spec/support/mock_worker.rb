class MockWorker < Struct.new(:klass, :id, :column, :callback)
  def self.perform(*args)
    new(*args).perform
  end

  def perform(*args)
    set_args(*args) unless args.empty?
  end

  def set_args(klass, id, column, callback = nil)
    self.klass, self.id, self.column, self.callback = klass, id, column, callback
  end
end

class MockSidekiqWorker < MockWorker
  include Sidekiq::Worker
end

class MockNamedSidekiqWorker < MockWorker
  include Sidekiq::Worker
  sidekiq_options queue: :even_better_name
end

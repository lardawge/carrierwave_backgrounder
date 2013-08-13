class SuckerPunchQueue
  include SuckerPunch::Job
  def perform(worker, *args)
    worker.new(*args).perform
  end
end

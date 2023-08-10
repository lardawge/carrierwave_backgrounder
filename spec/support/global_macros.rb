module GlobalMacros
  def load_file(full_path)
    File.open(full_path)
  end

  def file_count(path)
    Dir.entries(path).reject { |f| f =~ /\.\.$|\.$|\.gitkeep/ }.size
  end

  def process_latest_sidekiq_job
    job = Sidekiq::Queues["carrierwave"].pop
    worker = job['class'].constantize.new(*job['args'])
    worker.perform
  end
end
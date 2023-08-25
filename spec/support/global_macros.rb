module GlobalMacros
  def load_file(name)
    File.open("#{image_fixture_path}/#{name}")
  end

  def load_files(*names)
    names.map { |name| load_file(name) }
  end

  def image_fixture_path
    'spec/support/fixtures/images'
  end

  def file_count(path)
    Dir.entries(path).reject { |f| f =~ /\.\.$|\.$|\.gitkeep/ }.size
  end

  def process_latest_sidekiq_job
    job = Sidekiq::Queues["carrierwave"].pop
    worker_class = job['class']
    worker = worker_class.constantize.new

    worker.perform(*job['args'])
  end
end
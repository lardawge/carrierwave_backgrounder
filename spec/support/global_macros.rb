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
    Sidekiq::Job.drain_all
  end
end
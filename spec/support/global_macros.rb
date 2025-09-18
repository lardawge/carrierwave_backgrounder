module GlobalMacros
  def load_file(name, type: :image)
    File.open("#{fixture_path(type)}/#{name}")
  end

  def load_files(*names, type: :image)
    names.map { |name| load_file(name, type: type) }
  end

  def fixture_path(type = :image)
    "spec/support/fixtures/#{type.to_s.pluralize}"
  end

  def file_count(path)
    Dir.entries(path).reject { |f| f =~ /\.\.$|\.$|\.gitkeep/ }.size
  end

  def process_latest_sidekiq_job
    Sidekiq::Job.drain_all
  end

  def default_queue_name
    'carrierwave'
  end

  # A way to change backend configuration mid-test
  def reconfigure_backend(*models, &block)
    # It's necessary to re-run .configure, because it sets up the default workers, which
    # will become ancestors to overridden workers
    CarrierWave::Backgrounder.instance_variable_set('@backend', nil)
    CarrierWave::Backgrounder.configure(&block)

    # It's also necessary to reload models after changing the backend
    reload_models(*models)
  end

  # When CarrierWave::Backgrounder.configure happens the first time, from the initializer
  # where backend is set up, @worker_class gets set, and later on it's used in
  # store_in_background / process_in_background to define worker which will be used when
  # enqueuing, and it's only called once, when the model is loaded.
  # So if you change backend for tests, .configure does get called, but the method
  # #enqueue_#{column}_background_job still receives the old worker class.
  #
  # This is a hack to overcome this problem: reload the models so that methods
  # store_in_background / process_in_background can update the enqueuing methods
  def reload_models(*models)
    models.each do |model|
      load "spec/support/dummy_app/app/models/#{model}.rb"
    end
  end

  # Reset all changes to CarrierWave::Backgrounder configuration and reload models
  def reset_initializer_and_models(*models)
    CarrierWave::Backgrounder.instance_variable_set('@backend', nil)
    load 'spec/support/dummy_app/config/initializers/carrierwave_backgrounder.rb'

    reload_models(*models)
  end
end

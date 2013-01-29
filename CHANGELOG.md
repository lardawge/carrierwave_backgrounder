## 0.1.4 (unreleased)

### enhancements

### bug fixes
  * Remove the need to set an order in the Gemfile when using sidekiq [matthewsmart].

## 0.1.3

### enhancements
  * CarrierWave::Workers::ProcessAsset now uses #update_attribute when setting [column]_processing.

### bug fixes
  * Fix determine_backend behavior so that it doesn't throw an exception [petergoldstein].

## 0.1.2

### enhancements
  * Add a rails generator to generate the config file.
```bash
  rails g carrierwave_backgrounder:install
```

### bug fixes
  * Check [column]_cache to make sure we are processing when a form fails and [column]_cache is used.

## 0.1.1

### enhancements
  * Allow passing of all options to sidekiq in config file.

### bug fixes
  * Revert where sidekiq was broken due to Sidekiq::Worker not properly being included.

## 0.1.0

### enhancements
  * Add support to pass options to backends allowing queue names to be set in the initializer.
  * Make threadsafe. [gitt]
  * Add support to immediately process jobs if :immediate is set in config backend. [Antiarchitect]

### bug fixes
  * Girl Friday incorrectly referenses class #92
  * Add documentation for testing with rspec #84.


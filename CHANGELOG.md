## 0.2.1

### enhancements
  * [#119] Add support for SuckerPunch [rewritten].

### bug fixes
  * [#115] column_remove! should not trigger a background job
  * [#112] Raise a NoMethodError when using backend= instead of silent failure.

## 0.2.0

### enhancements
  * [Breaking Change] Require configure block to be set in an initializer removing autodetect backend.

### bug fixes
  * [#108] Remove the need to set an order in the Gemfile when using sidekiq [matthewsmart].

## 0.1.5

### bug fixes
  * [Revert #108] This is a breaking change and will be released in 0.2.0.

## 0.1.4

### bug fixes
  * [#109] Fix issue where setting Carrierwave.cache_dir to a full path would raise an exception [Sastopher].

## 0.1.3

### enhancements
  * CarrierWave::Workers::ProcessAsset now uses #update_attribute when setting [column]_processing.
  * [#104] Change the Sidekiq integration to use client_push [petergoldstein]

### bug fixes
  * [#103] Fix determine_backend behavior so that it doesn't throw an exception [petergoldstein].

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


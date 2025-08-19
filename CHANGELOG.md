## 1.1.0

### enhancements
  * Suppress NotFoundError if a record gets deleted before it is processed. This is configurable and defaults to true. [lardawge]

## 1.0.3

### enhancements
  * Add support for Rails 8.0 [damisul]

## 1.0.2

### bugfixes
  * [#317] Fixed an issue where #process_in_backfground would copy files but not create versions [Qqwy]
## 1.0.1

### bugfixes
  * [#315] Fix an issue where the expectation was a string key for config [fero46]

## 1.0.0
  * No Changes
## 1.0.0-beta.2

### enhancements
  * Now fully testing using different queue_adapters in CI

### bugfixes
  * Fix issue loading active_job

## 1.0.0-beta

### enhancements
  * Add native support for ActiveJob [lardawge]
  * Add support for multi-upload [lardawge]
  * Add rails app for testing so we can replicate real world conditions [lardawge]

### bugfixes
  * Fix issue where a new job would be queued when a upload was removed

### breaking changes
  * Remove support for after_save in favor of after_commit
  * Remove support for queueing systems other than ActiveJob and Sidekiq.

## 0.4.3

### enhancements
  * [#307] Add support for Sidekiq 7 [holstvoogd]
  * [#278] Add sidekiq queue config [IlkhamGaysin]

## 0.4.2

### enhancements
  * Allow overridden worker to set a queue name
  * [#190] Respect Carrierwave's enable_processing flag if set to false [jherdman]

### bug fixes
  * [#216] Fix for NoMethodError: undefined method `read' for nil:NilClass [kntmrkm]

## 0.4.1

### enhancements
  * [#179] Set column_processing to false instead of nil [mockdeep]

## 0.4.0

### enhancements
  * [#175] SuckerPunch v1.0 support (no longer support < 1.0). [janko-m]

### bug fixes
  * [#176] Check if record exists before running backgrounder [gdott9]
  * [#169] Correctly remove files on update if marked for deletion [sunny]

## 0.3.0

### enhancements
  * [#123] Fail silently when record not found in worker. [DouweM]

## 0.2.2

### bug fixes
  * [#141] Fix naming collisions of support module by namespacing.

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

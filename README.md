# CarrierWave Backgrounder

[![Build Status](https://github.com/lardawge/carrierwave_backgrounder/actions/workflows/ruby-ci.yml/badge.svg)](https://github.com/lardawge/carrierwave_backgrounder/actions/workflows/ruby-ci.yml)
[![Maintainability](https://qlty.sh/gh/lardawge/projects/carrierwave_backgrounder/maintainability.svg)](https://qlty.sh/gh/lardawge/projects/carrierwave_backgrounder)
---
**NOTICE**: Version 1.1.0 contains a change in behavior from previous version. When a record is deleted before the job is picked up, it will no longer raise an error. Prior to this change, when using `process_in_background`, if a record was missing, an error was raised. Some users might have relied on that. By default, this will no longer happen. If you want to maintain that behavior, you must set the `suppress_record_not_found_errors` configuration to `false`. This will raise a RecordNotFound error.

---
I am a fan of CarrierWave. That being said, I don't like tying up requests waiting for images to process.

This gem addresses that by offloading processing or storaging/processing to a background task.
We currently support ActiveJob and Sidekiq.

## Background Options

There are currently two offerings for backgrounding upload tasks which are as follows:

```ruby
# This stores the original file with no processing/versioning.
# It will upload the original file to s3.
# This was developed to use in cases where you do not have access to the cached location such as Heroku.

Backgrounder::ORM::Base::process_in_background
```

```ruby
# This does nothing to the file after it is cached which makes it fast.
# It requires a column in the database which stores the cache location set by carrierwave so the background job can access it.
# The drawback to using this method is the need for a central location to store the cached files.
#
# IMPORTANT: Only use this method if you have full control over your tmp storage directory and can mount it on every deployed server.

Backgrounder::ORM::Base::store_in_background
```

## Installation

These instructions assume you have previously set up [CarrierWave](https://github.com/jnicklas/carrierwave) and your queuing lib of choice.

Take a look at the [Rails app](spec/support/dummy_app) to see examples of setup.

In Rails, add the following to your `Gemfile`:

```ruby
gem 'carrierwave_backgrounder'
```

Run the generator which will create a `carrierwave_backgrounder.rb` initializer in the `config/initializers` folder:
```bash
rails g carrierwave_backgrounder:install
```

## Configuration

It's **necessary** to define a backend for background jobs. It defaults to `:active_job` in the generated `carrierwave_backgrounder.rb`.
Default queue name is `carrierwave`, even if it's not defined in the `carrierwave_backgrounder.rb` initializer.

### ActiveJob Configuration

You can use ActiveJob enqueue options (refer to `ActiveJob::Enqueuing#enqueue`) in global config:
```ruby
CarrierWave::Backgrounder.configure do |c|
  c.backend :active_job, queue: :awesome_queue, priority: 10
end
```

`ActiveJob` requires you to [set up the queueing backend](https://guides.rubyonrails.org/active_job_basics.html#configuring-the-backend) for it, because `ActiveJob` is only a mechanism to declare and execute background jobs on a queing backend such as e.g. Sidekiq:
```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq
```

### Sidekiq Configuration

You can pass additional configuration options to Sidekiq:

```ruby
CarrierWave::Backgrounder.configure do |c|
  c.backend :sidekiq, queue: :awesome_queue, size: 3
end
```

**IMPORTANT FOR SIDEKIQ BACKEND** - `carrierwave` (default queue name) should be added to your queue list or it will not run:

```yml
:queues:
  - [carrierwave, 1]
  - default
```

## Usage

In your CarrierWave uploader file you will need to add a cache directory as well as change cache_storage to `File`:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay

  # This is required if you are using S3 or any other remote storage.
  # CarrierWave's default is to store the cached file remotely which is slow and uses bandwidth.
  # By setting this to File, it will only store on saving of the record.
  cache_storage CarrierWave::Storage::File

  # It is recommended to set this to a persisted location if you are using `::store_in_background`.
  def cache_dir
    "path/that/persists"
  end

  # etc...
end
```

### To use `process_in_background`

In your model:

```ruby
mount_uploader :avatar, AvatarUploader
process_in_background :avatar
```

Optionally you can add a column to the database which will be set to `true` when
the background processing has started and to `false` when the background processing is complete.

This is set to true in the `after_commit` hook when the job is created. It is very useful if you are waiting to notify the user of completion.

```ruby
add_column :users, :avatar_processing, :boolean, null: false, default: false
```

### To use `store_in_background`

In your model:

```ruby
mount_uploader :avatar, AvatarUploader
store_in_background :avatar
```

Add a column to the model which will store the temp file location:

```ruby
add_column :users, :avatar_tmp, :string
```

## Usage Tips

### Bypass Backgrounding
If you need to process/store the upload immediately:

```ruby
@user.process_<column>_upload = true
```

This must be set before you assign an upload:

```ruby
@user = User.new
@user.process_avatar_upload = true
@user.attributes = params[:user]
```

### Override Worker

To override the worker in cases where additional methods need to be called, or you have app-specific requirements, pass the worker class as the second argument:

```ruby
process_in_background :avatar, MyParanoidWorker
```

Then create the worker that subclasses `carrierwave_backgrounder`'s worker.

Each method, `#store_in_background` and `#process_in_background`, has its own default worker for each of the supported backends.

<details open>
<summary>ActiveJob</summary>

  1. `process_in_background` subclass `::CarrierWave::Workers::ActiveJob::ProcessAsset`
  1. `store_in_background` subclass `::CarrierWave::Workers::ActiveJob::StoreAsset`

  ```ruby
  # ActiveJob Example

  # models/user.rb
  class User < ActiveRecord::Base
    mount_uploader :avatar, AvatarUploader
    process_in_background :avatar, AvatarUploaderJob
  end

  # jobs/avatar_uploader_job.rb
  class AvatarUploaderJob < ::CarrierWave::Workers::ActiveJob::ProcessAsset
    # ...or subclass CarrierWave::Workers::ActiveJob::StoreAsset if you're using `store_in_background`

    # It's possible to set the queue name per worker.
    # This will override :queue option set in the initializer
    queue_as :awesome_queue
    #
    # ActiveJob allows to pass a block to `queue_as` method to take advantage of `self.arguments` for a dynamically defined queue name:
    # queue_as do
    #   user = self.arguments.first
    #   user.premium? ? :high_priority_queue : :default
    # end
    #
    # If :queue was set in the initializer, 'default' and nil passed to :queue_as are ignored.
    # To force `default` queue over any :queue option set in the initializer, use a block:
    #   queue_as { 'default' }
    # or
    #   queue_as { nil }

    # Any other ActiveJob configuration options are available, e.g. for callbacks, see
    #   https://api.rubyonrails.org/classes/ActiveJob/Callbacks.html
    after_perform do
      # your code here
    end
  end
  ```

##### Custom `ApplicationJob`?

  If you have custom logics in your `ApplicationJob`, then you want to subclass `ApplicationJob` and then include:
  1. `::CarrierWave::Workers::ProcessAssetMixin` for `process_in_background`
  1. `::CarrierWave::Workers::StoreAssetMixin` for `store_in_background`

  ```ruby
  # jobs/avatar_uploader_job.rb
  class AvatarUploaderJob < ApplicationJob
    include ::CarrierWave::Workers::ProcessAssetMixin
    ...
  end
  ```

</details>

<br/>

<details open>
<summary>Sidekiq</summary>

  1. `process_in_background` subclass `::CarrierWave::Workers::ProcessAsset`
  1. `store_in_background` subclass `::CarrierWave::Workers::StoreAsset`

  ```ruby
  # Sidekiq Example

  class User < ActiveRecord::Base
    mount_uploader :avatar, AvatarUploader
    process_in_background :avatar, MyParanoidWorker
  end

  class MyParanoidWorker < ::CarrierWave::Workers::ProcessAsset
    # ...or subclass CarrierWave::Workers::StoreAsset if you're using `store_in_background`

    include Sidekiq::Worker

    # This will override :queue option set in the initializer
    sidekiq_options queue: :awesome_queue

    def error(job, exception)
      report_job_failure  # or whatever
    end

    # other hooks you might care about
  end
  ```

</details>

## License

Copyright (c) 2011 Larry Sprock

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

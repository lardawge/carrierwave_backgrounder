# CarrierWave Backgrounder

[![Build Status](https://app.travis-ci.com/lardawge/carrierwave_backgrounder.svg?branch=master)](https://app.travis-ci.com/lardawge/carrierwave_backgrounder)
[![Code Climate](https://codeclimate.com/github/lardawge/carrierwave_backgrounder.png)](https://codeclimate.com/github/lardawge/carrierwave_backgrounder)

I am a fan of CarrierWave. That being said, I don't like tying up requests waiting for images to process.

This gem addresses that by offloading processing or storaging/processing to a background task.
We currently support ActiveJob and Sidekiq.

## Background options

There are currently two offerings for backgrounding upload tasks which are as follows;

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

## Installation and Usage

These instructions assume you have previously set up [CarrierWave](https://github.com/jnicklas/carrierwave) and your queuing lib of choice.

In Rails, add the following your Gemfile:

```ruby
gem 'carrierwave_backgrounder'
```

Run the generator which will create an initializer in config/initializers.
```bash
rails g carrierwave_backgrounder:install
```

You can pass additional configuration options to Sidekiq:

```ruby
CarrierWave::Backgrounder.configure do |c|
  c.backend :sidekiq, queue: :awesome_queue, size: 3
end
```

**IMPORTANT FOR SIDEKIQ BACKEND** - Custom queue should be defined inside the Sidekiq configuration otherwise jobs won't process:

```yml
:queues:
  - [awesome_queue, 1]
  - default
```

In your CarrierWave uploader file:

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

  #etc...
end
```

### To use process_in_background

In your model:

```ruby
mount_uploader :avatar, AvatarUploader
process_in_background :avatar
```

Optionally you can add a column to the database which will be set to `true` when
the background processing has started and to `false` when the background processing is complete.

```ruby
add_column :users, :avatar_processing, :boolean, null: false, default: false
```

### To use store_in_background

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

### Bypass backgrounding
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

Useful in the console and is only needed when assigning a new asset, not when using `recreate_versions!`.

### Override worker
To override the worker in cases where additional methods need to be called or you have app specific requirements, pass the worker class as the
second argument:

```ruby
process_in_background :avatar, MyParanoidWorker
```

Then create a worker that subclasses carrierwave_backgrounder's worker:

```ruby
class MyParanoidWorker < ::CarrierWave::Workers::ProcessAsset
  # ...or subclass CarrierWave::Workers::StoreAsset if you're using store_in_background

  def error(job, exception)
    report_job_failure  # or whatever
  end

  # other hooks you might care about
end
```

### ActiveJob
Use overridden worker that inherits from ActiveJob::Base and includes relevant worker mixin:
```ruby
class MyActiveJobWorker < ActiveJob::Base
  include ::CarrierWave::Workers::ProcessAssetMixin
  # ... or include ::CarrierWave::Workers::StoreAssetMixin

  after_perform do
    # your code here
  end

  # Sometimes job gets performed before the file is uploaded and ready.
  # You can define how to handle that case by overriding `when_not_ready` method
  # (by default it does nothing)
  def when_not_ready
    retry_job
  end
end
```

Don't forget to set `active_job` as a backend in the config:
```ruby
CarrierWave::Backgrounder.configure do |c|
  c.backend :active_job, queue: :carrierwave
end
```

### Testing with Rspec
We use the after_commit hook when using active_record. This creates a problem when testing with Rspec because after_commit never gets fired
if you're using transactional fixtures. One solution to the problem is to use the [TestAfterCommit gem](https://github.com/grosser/test_after_commit).
There are various other solutions in which case google is your friend.

### Uploaders mounted on mongoid embedded documents
The workers fetch the document with the mounted uploader using the model class name and id. Uploads on embedded documents
cannot be obtained this way. If the position of the document in the root document structure is known, a workaround is to override the embedded models
find method like this:

```ruby
class SomeRootDocument
  include Mongoid::Document

  embeds_many :embedded_documents
end

class EmbeddedDocument
  include Mongoid::Document

  embedded_in :some_root_document

  process_in_background :image
  mount_uploader :image, ImageUploader

  def self.find(id)
    bson_id = Moped::BSON::ObjectId.from_string(id) # needed for Mongoid 3

    root = SomeRootDocument.where('embedded_documents._id' => bson_id).first
    root.embedded_documents.find(id)
  end
end
```

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

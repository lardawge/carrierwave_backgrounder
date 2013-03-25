# CarrierWave Backgrounder

[![Build Status](https://secure.travis-ci.org/lardawge/carrierwave_backgrounder.png)](http://travis-ci.org/lardawge/carrierwave_backgrounder)
[![Code Climate](https://codeclimate.com/github/lardawge/carrierwave_backgrounder.png)](https://codeclimate.com/github/lardawge/carrierwave_backgrounder)
[![Still Maintained](http://stillmaintained.com/lardawge/carrierwave_backgrounder.png)](http://stillmaintained.com/lardawge/carrierwave_backgrounder)

I like CarrierWave. That being said, I don't like tying up app instances waiting for images to process.

This gem addresses that by offloading processing or storage/processing to a background task.
We currently support Delayed Job, Resque, Sidekiq, SuckerPunch, Girl Friday, Qu, and Queue Classic.

## Background options

There are currently two offerings for backgrounding upload tasks which are as follows;

```ruby
# This stores the original file with no processing/versioning.
# It will upload the original file to s3.
# This was developed to use where you do not have control over the cache location such as Heroku.

Backgrounder::ORM::Base::process_in_background
```

```ruby
# This does nothing to the file after it is cached which makes it super fast.
# It requires a column in the database which stores the cache location set by carrierwave so the background job can access it.
# The drawback to using this method is the need for a central location to store the cached files.
# Heroku may deploy workers on separate servers from where your dyno cached the files.
#
# IMPORTANT: Only use this method if you have full control over your tmp storage directory.

Backgrounder::ORM::Base::store_in_background
```

## Installation and Usage

These instructions assume you have previously set up [CarrierWave](https://github.com/jnicklas/carrierwave) and your queing lib of choice.

In Rails, add the following your Gemfile:

```ruby
gem 'carrierwave_backgrounder'
```

Run the generator which will create an initializer in config/initializers.
```bash
  rails g carrierwave_backgrounder:install
```

You can pass additional configuration options to Girl Friday and Sidekiq:

```ruby
CarrierWave::Backgrounder.configure do |c|
  c.backend :girl_friday, queue: :awesome_queue, size: 3, store: GirlFriday::Store::Redis
end
```

For SuckerPunch, you have to configure your queue with a specific worker.

```ruby
CarrierWave::Backgrounder.configure do |c|
  c.backend :sucker_punch, queue: :carrierwave
end

# It is important to configure sucker_punch after carrierwave_backgrounder
SuckerPunch.config do
  queue name: :carrierwave, worker: CarrierWave::Workers::StoreAsset, size: 2
end
```


In your CarrierWave uploader file:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay

  #etc...
end
```

### To use process_in_background

In your model:

```ruby
mount_uploader :avatar, AvatarUploader
process_in_background :avatar
```

Optionally you can add a column to the database which will be set to nil when the background processing is complete.

```ruby
add_column :users, :avatar_processing, :boolean
```

### To use store_in_background

In your model:

```ruby
mount_uploader :avatar, AvatarUploader
store_in_background :avatar
```

Add a column to the model you want to background which will store the temp file location:

```ruby
add_column :users, :avatar_tmp, :string
```

## Usage Tips

### Bypass backgrounding
If you need to process/store the upload immediately:

```ruby
@user.process_<column>_upload = true
```

### Override worker
To overide the worker in cases where additional methods need to be called or you have app specific requirements, pass the worker class as the
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
### Testing with Rspec
We use the after_commit hook when using active_record. This creates a problem when testing with Rspec because after_commit never gets fired
if you're using trasactional fixtures. One solution to the problem is to use the [TestAfterCommit gem](https://github.com/grosser/test_after_commit).
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

  mount_uploader :image, ImageUploader
  process_in_background :image

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

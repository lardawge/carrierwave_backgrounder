# CarrierWave Backgrounder [![Build Status](https://secure.travis-ci.org/lardawge/carrierwave_backgrounder.png)](http://travis-ci.org/lardawge/carrierwave_backgrounder)

I like CarrierWave. That being said, I don't like tying up app instances waiting for images to process.

This gem addresses that issue by disabling processing until a background process initiates it.
It supports Delayed Job, Resque and Girl Friday.

## Background options

There are currently two offerings for backgrounding upload tasks which are as follows;

```ruby
Backgrounder::ORM::Base::process_in_background
```

This method stores the original file and does no processing or versioning. Optionally you can add a column to the database which will be set to nil when the background processing is complete.

```ruby
Backgrounder::ORM::Base::store_in_background
```

This method does nothing to the file after it is cached which makes it super fast. It requires a column in the database which stores the cache location set by carrierwave. The drawback to using this method is the need for a central location to store the cached files. This leave heroku out. Heroku may deploy workers on separate servers from where your dyno cached the files. That being said, I only recommend using this method if you have full control over your temp storage directory.

## Installation

These instructions assume you have previously set up [CarrierWave](https://github.com/jnicklas/carrierwave) and [DelayedJob](https://github.com/collectiveidea/delayed_job) or Resque

In Rails, add the following your Gemfile:

```ruby
gem 'carrierwave_backgrounder'
```

## Getting Started

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

If you need to process/store the upload immediately:

```ruby
@user.process_<column>_upload = true
```

To overide the worker in cases where additional methods need to be called or you have app specific requirements, pass the worker class as the
second argument:

```ruby
process_in_background :avatar, MyAppsAwesomeProcessingWorker
```

## ORM

Currently ActiveRecord is the default orm and I have not tested this with others but it should work by adding the following to your carrierwave initializer:

```ruby
DataMapper::Model.send(:include, ::CarrierWave::Backgrounder::ORM::Base)
# or
Mongoid::Document::ClassMethods.send(:include, ::CarrierWave::Backgrounder::ORM::Base)
# or
Sequel::Model.send(:extend, ::CarrierWave::Backgrounder::ORM::Base)
```

## Callbacks

Callbacks are supported for Delayed Job, and include all 6 callbacks which [DJ makes available](https://github.com/collectiveidea/delayed_job) (enqueue, before, after, success, error, failure):

```ruby
def enqueue(job)
  if @record.respond_to?(:enqueue_callback)
    @record.enqueue_callback(job)
  end
end
def before(job)
  #duplication
end

def after(job)
  #duplication
end
```

etc...

To make use of these callbacks, just equip your model with methods named after the callbacks made to the job. IE. callback_enqueue, callback_before, etc...
```ruby
class Asset < ActiveRecord::Base
  def callback_enqueue(job)
    # do something interesting with the fact that DJ just told you that your job was just enqueued
  end
  def callback_before(job)
    # cool code omitted
  end

  def callback_after(job)
    # you know the drill
  end
end
```


Contributions are gladly accepted from those who use these orms.

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

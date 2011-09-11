# CarrierWave Backgrounder

I like CarrierWave. That being said, I don't like tying up app instances waiting for images to process. This gem addresses that issue.

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

These instructions assume you have previously set up [CarrierWave](https://github.com/jnicklas/carrierwave) and [DelayedJob](https://github.com/collectiveidea/delayed_job)

In Rails, add the following your Gemfile:

```ruby
gem 'carrierwave_backgrounder'
```

## Getting Started

### To use process_in_background
    
In your model:
    
```ruby
mount_uploader :avatar, AvatarUploader
process_in_background :avatar
```

### To use store_in_background
    
In your model:

```ruby
mount_uploader :avatar, AvatarUploader
process_in_background :avatar
```

Add a column to the model you want to background which will store the temp file location:

```ruby
add_column :users, :avatar_tmp, :string
```

In your CarrierWave uploader file:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::DelayStorage

  #ect...
end
```

## Usage Tips

If you need to process/store the upload immediately:

```ruby
@user.process_<column>_upload = true 
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

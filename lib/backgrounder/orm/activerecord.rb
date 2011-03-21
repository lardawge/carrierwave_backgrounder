require 'backgrounder/extend_orm'
::ActiveRecord::Base.send :include, ::CarrierWave::Backgrounder::ORM
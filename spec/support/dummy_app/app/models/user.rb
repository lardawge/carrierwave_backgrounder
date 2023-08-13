class User < ApplicationRecord
  # Single attachment support
  mount_uploader :avatar, AvatarUploader
  store_in_background :avatar

  # Multi attachment support
  mount_uploaders :images, AvatarUploader
  store_in_background :images
  serialize :images, JSON
end

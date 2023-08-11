class User < ApplicationRecord
  # Single attachement support
  mount_uploader :avatar, AvatarUploader
  store_in_background :avatar

  # Multi attachement support
  mount_uploaders :images, AvatarUploader
  store_in_background :images
  serialize :images, JSON
end

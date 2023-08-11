class Admin < ApplicationRecord
  # Single attachment support
  mount_uploader :avatar, AvatarUploader
  process_in_background :avatar

  # Multi attachment support
  mount_uploaders :images, AvatarUploader
  process_in_background :images
  serialize :images, JSON
end

class Admin < ApplicationRecord
  mount_uploader :avatar, AvatarUploader
  process_in_background :avatar
end

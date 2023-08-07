class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader
  store_in_background :avatar
end

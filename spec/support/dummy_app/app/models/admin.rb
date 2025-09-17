class Admin < ApplicationRecord
  # Single attachment support
  mount_uploader :avatar, AvatarUploader
  process_in_background :avatar

  # Multi attachment support
  mount_uploaders :images, AvatarUploader
  process_in_background :images
  serialize :images, coder: JSON

  # Override worker
  mount_uploaders :documents, DocumentUploader
  process_in_background :documents, DocumentUploaderActiveJob
end

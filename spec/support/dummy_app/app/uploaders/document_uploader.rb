require 'carrierwave'

class DocumentUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay

  # Choose what kind of storage to use for this uploader:
  # storage :aws
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def cache_dir
    "../tmp/documents"
  end

  # Add an allowlist of extensions which are allowed to be uploaded.
  # For documents you might use something like this:
  # def extension_allowlist
  #   %w(pdf doc docx xls xlsx txt rtf)
  # end

  # Add an allowlist of content types which are allowed to be uploaded.
  # For documents you might use something like this:
  # def content_type_allowlist
  #   %w[
  #     application/pdf
  #     application/msword
  #     application/vnd.openxmlformats-officedocument.wordprocessingml.document
  #     application/vnd.ms-excel
  #     application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  #     text/plain
  #     application/rtf
  #     text/rtf
  #   ]
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.pdf" if original_filename
  # end
end

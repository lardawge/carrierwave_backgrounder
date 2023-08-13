class AddImagesToAdmins < ActiveRecord::Migration[7.0]
  def change
    add_column :admins, :images, :string
    add_column :admins, :images_processing, :boolean, null: false, default: false
  end
end

class AddImagesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :images, :string
    add_column :users, :images_tmp, :string
    add_column :users, :images_processing, :boolean, null: false, default:false
  end
end

class AddAvatarProcessingFlagToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :avatar_processing, :boolean, null: false, default: false
  end
end

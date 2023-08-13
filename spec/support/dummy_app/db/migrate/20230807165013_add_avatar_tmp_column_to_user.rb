class AddAvatarTmpColumnToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :avatar_tmp, :string
  end
end

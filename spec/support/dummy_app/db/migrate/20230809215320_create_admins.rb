class CreateAdmins < ActiveRecord::Migration[7.0]
  def change
    create_table :admins do |t|
      t.string :avatar
      t.boolean :avatar_processing, null: false, default: false

      t.timestamps
    end
  end
end

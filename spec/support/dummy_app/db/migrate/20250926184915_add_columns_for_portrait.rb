class AddColumnsForPortrait < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :portrait, :string
    add_column :users, :portrait_tmp, :string
    add_column :users, :portrait_processing, :boolean, null: false, default:false
  end
end

class AddDocumentsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :documents, :string
    add_column :users, :documents_tmp, :string
    add_column :users, :documents_processing, :boolean, null: false, default: false
  end
end

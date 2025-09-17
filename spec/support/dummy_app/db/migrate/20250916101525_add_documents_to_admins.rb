class AddDocumentsToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :documents, :string
    add_column :admins, :documents_processing, :boolean, null: false, default: false
  end
end

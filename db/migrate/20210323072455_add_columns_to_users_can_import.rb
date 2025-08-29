class AddColumnsToUsersCanImport < ActiveRecord::Migration
  def change
    add_column :users, :can_import, :boolean, default: false
  end
end

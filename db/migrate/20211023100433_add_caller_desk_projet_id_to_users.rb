class AddCallerDeskProjetIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :caller_desk_project_id, :integer
  end
end

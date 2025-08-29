class AddFieldToUsers < ActiveRecord::Migration
  def change
    add_column :users, :can_delete_lead, :boolean, default: false
  end
end

class AddColumnToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_calling_executive, :boolean
  end
end

class ChangeDeadStatusColumnsType < ActiveRecord::Migration
  def up
    remove_column :companies, :dead_status_id, :integer
    add_column :companies, :dead_status_ids, :text, array: true, default: []
  end

  def down
    remove_column :companies, :dead_status_ids, :text, array: true, default: []
    add_column :companies, :dead_status_id, :integer
  end
end

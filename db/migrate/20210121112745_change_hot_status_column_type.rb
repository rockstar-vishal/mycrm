class ChangeHotStatusColumnType < ActiveRecord::Migration
  def up
    remove_column :companies, :hot_status_id, :integer
    add_column :companies, :hot_status_ids, :text, array: true, default: []
  end

  def down
    remove_column :companies, :hot_status_ids, :text, array: true, default: []
    add_column :companies, :hot_status_id, :integer
  end
end

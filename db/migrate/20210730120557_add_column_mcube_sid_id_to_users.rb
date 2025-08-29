class AddColumnMcubeSidIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mcube_sid_id, :integer, index: true
  end
end

class AddColumnLeadIdToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :lead_id, :integer
  end
end

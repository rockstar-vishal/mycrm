class ChangeColumnFieldsToNotifications < ActiveRecord::Migration
  def change
    change_column :notifications, :field, "JSON USING CAST(field AS json)"
  end
end

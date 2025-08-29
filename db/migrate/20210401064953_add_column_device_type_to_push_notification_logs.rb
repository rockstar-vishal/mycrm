class AddColumnDeviceTypeToPushNotificationLogs < ActiveRecord::Migration
  def change
    add_column :push_notification_logs, :device_type, :integer
  end
end

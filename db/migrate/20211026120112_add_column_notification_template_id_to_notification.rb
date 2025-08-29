class AddColumnNotificationTemplateIdToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :notification_template_id, :integer, index: true
  end
end

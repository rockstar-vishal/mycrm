class CreatePushNotificationSettings < ActiveRecord::Migration
  def change
    create_table :push_notification_settings do |t|
      t.string :token
      t.string :project_key
      t.integer :company_id, index: true
      t.boolean :is_active, :boolean, default: false

      t.timestamps
    end
  end
end

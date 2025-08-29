class CreatePushNotificationLogs < ActiveRecord::Migration
  def change
    create_table :push_notification_logs do |t|
      t.integer :company_id, index: true
      t.integer :user_id, index: true
      t.integer :push_notification_id
      t.integer :lead_id, index: true
      t.text :response
      t.datetime :sent_at
      t.timestamps
    end
  end
end

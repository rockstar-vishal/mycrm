class CreateLeadsCallLogs < ActiveRecord::Migration
  def change
    create_table :leads_call_logs do |t|
      t.integer  :lead_id
      t.string :sid
      t.datetime :start_time
      t.datetime :end_time
      t.string :to_number
      t.string :from_number
      t.string :duration
      t.string :recording_url
      t.json  :other_data, default: {}

      t.timestamps
    end
  end
end

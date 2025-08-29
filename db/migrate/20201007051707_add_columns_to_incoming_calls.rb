class AddColumnsToIncomingCalls < ActiveRecord::Migration
  def change
    add_column :incoming_calls, :to_number, :string
    add_column :incoming_calls, :end_time, :datetime
    add_column :incoming_calls, :duration, :string
    add_column :incoming_calls, :recording_url, :string
    add_column :incoming_calls, :other_data, :json, default: {}
  end
end

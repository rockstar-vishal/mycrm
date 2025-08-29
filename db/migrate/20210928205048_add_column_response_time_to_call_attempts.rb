class AddColumnResponseTimeToCallAttempts < ActiveRecord::Migration
  def change
    add_column :call_attempts, :response_time, :float
  end
end

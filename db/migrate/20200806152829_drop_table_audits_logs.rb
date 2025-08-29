class DropTableAuditsLogs < ActiveRecord::Migration
  def change
    drop_table :audit_logs
  end
end

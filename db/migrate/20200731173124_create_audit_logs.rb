class CreateAuditLogs < ActiveRecord::Migration
  def change
    create_table :audit_logs do |t|
      t.integer :company_id
      t.integer :lead_id
      t.integer :user_id
      t.json :change_list

      t.timestamps
    end
  end
end

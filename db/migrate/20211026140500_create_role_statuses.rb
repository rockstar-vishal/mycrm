class CreateRoleStatuses < ActiveRecord::Migration
  def change
    create_table :role_statuses do |t|
      t.integer :role_id
      t.text :status_ids, array: true, default: []
      t.integer :company_id

      t.timestamps
    end
  end
end

class CreateCallAttempts < ActiveRecord::Migration
  def change
    create_table :call_attempts do |t|
      t.integer :lead_id, index: true
      t.integer :user_id, index: true

      t.timestamps
    end
  end
end

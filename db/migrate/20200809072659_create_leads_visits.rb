class CreateLeadsVisits < ActiveRecord::Migration
  def change
    create_table :leads_visits do |t|
      t.integer :lead_id
      t.date :date
      t.text :comment

      t.timestamps
    end
  end
end

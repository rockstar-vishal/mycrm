class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.text :body
      t.text :field
      t.string :name
      t.integer :company_id

      t.timestamps
    end
  end
end

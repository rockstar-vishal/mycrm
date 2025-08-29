class CreateLoans < ActiveRecord::Migration
  def change
    create_table :loans do |t|
      t.integer :company_id
      t.integer :lead_id
      t.datetime :ncd
      t.text :comment
      t.integer :status_id
      t.integer :user_id

      t.timestamps
    end
  end
end

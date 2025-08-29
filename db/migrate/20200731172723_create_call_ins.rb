class CreateCallIns < ActiveRecord::Migration
  def change
    create_table :call_ins do |t|
      t.integer :company_id
      t.string :number
      t.integer :project_id
      t.integer :user_id
      t.string :source_name
      t.boolean :active, default: true

      t.timestamps
    end
  end
end

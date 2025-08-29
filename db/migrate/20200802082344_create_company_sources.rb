class CreateCompanySources < ActiveRecord::Migration
  def change
    create_table :company_sources do |t|
      t.integer :source_id, index: true
      t.integer :company_id, index: true
      t.timestamps
    end
  end
end

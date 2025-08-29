class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.integer :company_id
      t.integer :city_id
      t.text :address
      t.boolean :active, default: true

      t.timestamps
    end
  end
end

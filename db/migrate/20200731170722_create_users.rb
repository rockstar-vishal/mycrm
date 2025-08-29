class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :mobile
      t.string :email
      t.integer :role_id
      t.string :city
      t.string :state
      t.string :country
      t.integer :company_id
      t.boolean :active, default: true

      t.timestamps
    end
  end
end

class CreateBrokers < ActiveRecord::Migration
  def change
    create_table :brokers do |t|
      t.string :name
      t.string :email
      t.string :mobile
      t.string :firm_name
      t.string :locality
      t.string :rera_number
      t.integer :company_id

      t.timestamps
    end
  end
end

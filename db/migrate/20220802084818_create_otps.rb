class CreateOtps < ActiveRecord::Migration
  def change
    create_table :otps do |t|
      t.integer :user_id, index: true
      t.integer :company_id, index: true
      t.string :validation_type
      t.string :validatable_data
      t.string :code
      t.boolean :used, default: false
      t.integer :resource_id, index: true
      t.string :resource_type, index: true
      t.integer :event_type

      t.timestamps
    end
  end
end

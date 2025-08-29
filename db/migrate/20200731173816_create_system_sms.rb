class CreateSystemSms < ActiveRecord::Migration
  def change
    create_table :system_sms do |t|
      t.integer :company_id
      t.integer :user_id
      t.integer :messageable_id
      t.string :messageable_type
      t.text :text
      t.string :response
      t.boolean :sent

      t.timestamps
    end
  end
end

class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.integer :sender_id
      t.string :sender_type
      t.integer :receiver_id
      t.string :receiver_type
      t.text :body
      t.text :cc_email, array: true, default: []
      t.string :subject
      t.boolean :sent
      t.text :response

      t.timestamps
    end
  end
end

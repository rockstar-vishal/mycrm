class CreateUsersTokens < ActiveRecord::Migration
  def change
    create_table :users_tokens do |t|
      t.integer :user_id
      t.string :token

      t.timestamps
    end
  end
end

class CreateUsersManagers < ActiveRecord::Migration
  def change
    create_table :users_managers do |t|
      t.integer :user_id
      t.integer :manager_id

      t.timestamps
    end
  end
end

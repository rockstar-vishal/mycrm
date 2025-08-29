class CreateUsersSearchHistories < ActiveRecord::Migration
  def change
    create_table :users_search_histories do |t|
      t.integer :user_id
      t.string :name
      t.json :search_params, null: false, default: {}

      t.timestamps
    end
  end
end

class CreateUsersProjects < ActiveRecord::Migration
  def change
    create_table :users_projects do |t|
      t.integer :project_id, index: true
      t.integer :user_id, index: true

      t.timestamps
    end
  end
end

class CreateRoundRobinSettings < ActiveRecord::Migration
  def change
    create_table :round_robin_settings do |t|
      t.integer :user_id
      t.integer :source_id
      t.integer :sub_source_id
      t.integer :project_id

      t.timestamps
    end
  end
end

class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.string :title
      t.date :start_date
      t.date :end_date
      t.integer  :budget
      t.integer  :source_id, index: true
      t.uuid :uuid,            default: "uuid_generate_v4()"
      t.timestamps
    end
  end
end

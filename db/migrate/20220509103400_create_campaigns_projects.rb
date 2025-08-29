class CreateCampaignsProjects < ActiveRecord::Migration
  def change
    create_table :campaigns_projects do |t|
      t.integer :campaign_id, index: true
      t.integer :project_id, index: true

      t.timestamps
    end
  end
end

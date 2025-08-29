class CreateFbAdsIds < ActiveRecord::Migration
  def change
    create_table :fb_ads_ids do |t|
      t.string :number
      t.integer :project_id, index: true
      t.timestamps
    end
  end
end

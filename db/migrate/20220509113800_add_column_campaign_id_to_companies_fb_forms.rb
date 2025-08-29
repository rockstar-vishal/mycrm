class AddColumnCampaignIdToCompaniesFbForms < ActiveRecord::Migration
  def change
    add_column :companies_fb_forms, :campaign_id, :integer, index: true
  end
end

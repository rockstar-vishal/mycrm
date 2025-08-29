class AddCompanyIdToCampaign < ActiveRecord::Migration
  def change
    add_column :campaigns, :company_id, :integer, index: true
  end
end

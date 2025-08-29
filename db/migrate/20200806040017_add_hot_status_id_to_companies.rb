class AddHotStatusIdToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :hot_status_id, :integer
  end
end

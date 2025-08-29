class AddNewStatusIdToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :new_status_id, :integer
  end
end

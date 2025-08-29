class AddTokenStatusToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :token_status_ids, :text, array: true, default: []
  end
end

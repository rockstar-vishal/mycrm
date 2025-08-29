class AddRemoveClosedToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :remove_closed, :boolean, default: false
  end
end

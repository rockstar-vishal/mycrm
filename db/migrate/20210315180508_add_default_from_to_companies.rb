class AddDefaultFromToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :default_from_email, :string
  end
end

class AddColumnMobileDomainToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :mobile_domain, :string
  end
end

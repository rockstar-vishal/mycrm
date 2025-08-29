class AddVisitAllowedFieldToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :visits_allowed_fields, :text, array: true, default: []
  end
end

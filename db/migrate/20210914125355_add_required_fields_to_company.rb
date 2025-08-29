class AddRequiredFieldsToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :required_fields, :text, array: true, default: []
  end
end

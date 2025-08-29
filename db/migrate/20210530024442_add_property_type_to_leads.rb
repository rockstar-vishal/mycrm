class AddPropertyTypeToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :property_type, :string
    add_column :companies, :requirement, :boolean, default: false
  end
end

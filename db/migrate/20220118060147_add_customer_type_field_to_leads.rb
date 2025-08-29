class AddCustomerTypeFieldToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :customer_type, :integer
  end
end

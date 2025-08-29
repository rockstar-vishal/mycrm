class AddLeaseExpiryDateToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :lease_expiry_date, :date
  end
end

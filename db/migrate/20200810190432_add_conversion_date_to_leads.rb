class AddConversionDateToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :conversion_date, :date
  end
end

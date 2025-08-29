class AddColumnOtherDataToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :other_data, :json, default: {}
  end
end

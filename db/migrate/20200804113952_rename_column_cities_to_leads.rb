class RenameColumnCitiesToLeads < ActiveRecord::Migration
  def change
    rename_column :leads, :city, :city_id
    change_column :leads, :city_id, 'Integer USING CAST(city_id AS Integer)'
  end
end

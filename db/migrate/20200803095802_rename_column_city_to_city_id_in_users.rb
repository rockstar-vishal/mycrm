class RenameColumnCityToCityIdInUsers < ActiveRecord::Migration
  def change
    rename_column :users, :city, :city_id
    change_column :users, :city_id, 'Integer USING CAST(city_id AS Integer)'
  end
end

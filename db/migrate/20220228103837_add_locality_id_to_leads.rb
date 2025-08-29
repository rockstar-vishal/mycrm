class AddLocalityIdToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :locality_id, :integer
  end
end

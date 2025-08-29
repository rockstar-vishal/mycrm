class AddIndexToLeads < ActiveRecord::Migration
  def change
    add_index :leads, :locality_id
  end
end

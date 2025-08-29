class AddBrokerIdToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :broker_id, :integer
  end
end

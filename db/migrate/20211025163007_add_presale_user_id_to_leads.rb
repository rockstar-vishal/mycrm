class AddPresaleUserIdToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :presale_user_id, :integer
  end
end

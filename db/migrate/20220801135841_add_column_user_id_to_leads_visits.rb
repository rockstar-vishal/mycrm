class AddColumnUserIdToLeadsVisits < ActiveRecord::Migration
  def change
    add_column :leads_visits, :user_id, :integer, index: true
  end
end

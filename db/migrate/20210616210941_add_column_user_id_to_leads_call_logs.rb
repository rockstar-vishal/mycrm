class AddColumnUserIdToLeadsCallLogs < ActiveRecord::Migration
  def change
    add_column :leads_call_logs, :user_id, :integer, index: true
  end
end

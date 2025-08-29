class AddColumnThirdPartyIdToCallLogs < ActiveRecord::Migration
  def change
    add_column :leads_call_logs, :third_party_id, :integer, default: 1
  end
end

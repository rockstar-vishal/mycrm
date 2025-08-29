class AddColumnCzentrixcloudEnabledAgentIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :czentrixcloud_enabled, :boolean, default: false
    add_column :users, :agent_id, :string
  end
end

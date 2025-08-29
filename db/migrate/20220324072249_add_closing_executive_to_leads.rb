class AddClosingExecutiveToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :closing_executive, :integer
    add_column :users, :is_meeting_executive, :boolean, :default => false
  end
end

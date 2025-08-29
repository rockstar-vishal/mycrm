class AddVisitExecutedToLeads < ActiveRecord::Migration
  def change
    add_column :leads_visits, :is_visit_executed, :boolean, default: false
    add_column :leads_visits, :is_postponed, :boolean, default: false
    add_column :leads_visits, :is_canceled, :boolean, default: false
  end
end

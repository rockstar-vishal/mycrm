class AddFieldsToLeadsVisits < ActiveRecord::Migration
  def change
    add_column :leads_visits, :location, :string
    add_column :leads_visits, :surronding, :string
    add_column :leads_visits, :finalization_period, :string
    add_column :leads_visits, :loan_sanctioned, :string
    add_column :leads_visits, :bank_name, :string
    add_column :leads_visits, :loan_amount, :string
    add_column :leads_visits, :eligibility, :string
    add_column :leads_visits, :own_contribution_minimum, :string
    add_column :leads_visits, :own_contribution_maximum, :string
    add_column :leads_visits, :loan_requirements, :string
  end
end

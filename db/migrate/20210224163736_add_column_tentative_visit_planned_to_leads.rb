class AddColumnTentativeVisitPlannedToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :tentative_visit_planned, :datetime
  end
end

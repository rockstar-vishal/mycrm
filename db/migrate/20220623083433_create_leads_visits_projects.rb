class CreateLeadsVisitsProjects < ActiveRecord::Migration
  def change
    create_table :leads_visits_projects do |t|
      t.integer :visit_id, index: true
      t.integer :project_id, index: true
    end
  end
end

class AddSiteVisitDoneToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :site_visit_done_id, :integer
  end
end

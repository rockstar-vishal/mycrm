class AddAttachmentSiteVisitFormToLeadsVisits < ActiveRecord::Migration
  def self.up
    change_table :leads_visits do |t|
      t.attachment :site_visit_form
    end
  end

  def self.down
    remove_attachment :leads_visits, :site_visit_form
  end
end

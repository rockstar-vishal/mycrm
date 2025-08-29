class AddRevisitToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :revisit, :boolean, default: false
  end
end

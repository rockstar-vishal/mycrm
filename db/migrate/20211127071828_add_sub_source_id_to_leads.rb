class AddSubSourceIdToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :enquiry_sub_source_id, :integer
  end
end

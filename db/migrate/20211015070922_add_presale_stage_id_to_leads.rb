class AddPresaleStageIdToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :presale_stage_id, :integer
  end
end

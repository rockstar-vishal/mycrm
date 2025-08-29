class AddColumnStagesToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :stage, :string
  end
end

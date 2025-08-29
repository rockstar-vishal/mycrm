class AddSubSourceToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :sub_source, :string
  end
end

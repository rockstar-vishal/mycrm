class AddColumnIsSelectListAndItemsToMagicFields < ActiveRecord::Migration
  def change
    add_column :magic_fields, :is_select_list, :boolean, default: false
    add_column :magic_fields, :items, :text, array: true, default: []
  end
end

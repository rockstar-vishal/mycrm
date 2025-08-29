class AddColumnsToMagicFields < ActiveRecord::Migration
  def change
    add_column :magic_fields, :is_indexed_field, :boolean, default: false
    add_column :magic_fields, :is_popup_field, :boolean, default: false
  end
end

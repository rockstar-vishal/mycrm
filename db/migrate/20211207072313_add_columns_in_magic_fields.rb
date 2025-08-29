class AddColumnsInMagicFields < ActiveRecord::Migration
  def change
    add_column :magic_fields, :fb_form_field, :boolean, default: false
    add_column :magic_fields, :fb_field_name, :string
  end
end

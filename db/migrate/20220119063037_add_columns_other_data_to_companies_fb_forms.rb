class AddColumnsOtherDataToCompaniesFbForms < ActiveRecord::Migration
  def change
    add_column :companies_fb_forms, :other_data, :json, default: {}
  end
end

class AddTitleToCompaniesFbForms < ActiveRecord::Migration
  def change
    add_column :companies_fb_forms, :title, :string
  end
end

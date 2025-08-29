class CreateCompaniesFbForms < ActiveRecord::Migration
  def change
    create_table :companies_fb_forms do |t|
      t.integer :company_id
      t.integer :project_id
      t.string :form_no
      t.text :bind_comment
      t.boolean :active, default: true

      t.timestamps
    end
    add_column :companies, :fb_access_token, :text
  end
end

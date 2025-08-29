class CreateCompaniesFbPages < ActiveRecord::Migration
  def change
    remove_column :companies, :fb_access_token, :text
    add_column :companies_fb_forms, :fb_page_id, :integer
    create_table :companies_fb_pages do |t|
      t.string :title
      t.integer :company_id
      t.string :page_fbid
      t.text :access_token

      t.timestamps
    end
  end
end

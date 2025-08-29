class CreateCompaniesApiKeys < ActiveRecord::Migration
  def change
    create_table :companies_api_keys do |t|
      t.integer :company_id
      t.string :key
      t.integer :source_id
      t.integer :user_id
      t.integer :project_id

      t.timestamps
    end
    add_column :companies, :uuid, :uuid, default: "uuid_generate_v4()"
  end
end

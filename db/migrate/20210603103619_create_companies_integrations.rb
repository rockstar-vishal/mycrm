class CreateCompaniesIntegrations < ActiveRecord::Migration
  def change
    create_table :companies_integrations do |t|
      t.integer :company_id
      t.string :key
      t.text :title
      t.json :data, default: {}, null: false
      t.boolean :active, default: true

      t.timestamps
    end
  end
end

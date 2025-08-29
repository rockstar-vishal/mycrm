class CreateCompaniesReasons < ActiveRecord::Migration
  def change
    remove_column :companies, :rejection_reasons, :text
    remove_column :leads, :dead_reason, :string
    add_column :leads, :dead_reason_id, :integer
    create_table :companies_reasons do |t|
      t.integer :company_id
      t.string :reason
      t.boolean :active, default: true

      t.timestamps
    end
  end
end

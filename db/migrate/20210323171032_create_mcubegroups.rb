class CreateMcubegroups < ActiveRecord::Migration
  def change
    create_table :mcubegroups do |t|
      t.string :number
      t.integer :company_id, index: true
      t.boolean :is_active, default: false
      t.string :group_name

      t.timestamps
    end
  end
end

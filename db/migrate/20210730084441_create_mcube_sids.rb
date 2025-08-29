class CreateMcubeSids < ActiveRecord::Migration
  def change
    create_table :mcube_sids do |t|
      t.string :number
      t.string :description
      t.boolean :is_active
      t.integer :company_id, index: true
      t.uuid :uuid, default: "uuid_generate_v4()"
      t.timestamps
    end
  end
end

class CreateSubSources < ActiveRecord::Migration
  def change
    create_table :sub_sources do |t|
      t.string :name
      t.uuid :uuid, default: "uuid_generate_v4()"
      t.integer :company_id
      t.timestamps
    end
  end
end

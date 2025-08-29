class CreateExotelSids < ActiveRecord::Migration
  def change
    create_table :exotel_sids do |t|
      t.string :number
      t.string :description
      t.boolean :is_active, default: true
      t.integer :company_id, :integer, index: true
      t.uuid :uuid,            default: "uuid_generate_v4()"

      t.timestamps
    end
  end
end

class CreateCommercialTypes < ActiveRecord::Migration
  def change
    create_table :commercial_types do |t|
      t.string :property_type
      t.string :purpose
      t.string :area_unit
      t.integer :plot_area_from
      t.integer :plot_area_to
      t.text :purpose_comment
      t.boolean :is_attached_toilet
      t.integer :lead_id
      t.timestamps
    end
  end
end

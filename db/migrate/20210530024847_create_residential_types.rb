class CreateResidentialTypes < ActiveRecord::Migration
  def change
    create_table :residential_types do |t|
      t.string :property_type
      t.string :purpose
      t.string :area_config
      t.string :area_unit
      t.integer :plot_area_from
      t.integer :plot_area_to
      t.integer :lead_id
      t.timestamps
    end
  end
end

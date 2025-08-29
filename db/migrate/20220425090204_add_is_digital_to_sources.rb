class AddIsDigitalToSources < ActiveRecord::Migration
  def change
    add_column :sources, :is_digital, :boolean, default: false
  end
end

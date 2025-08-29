class IsCpToSources < ActiveRecord::Migration
  def change
    add_column :sources, :is_cp, :boolean, default: false
  end
end

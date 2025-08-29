class AddColumnPropertiesCodesToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :property_codes, :text, array: true, index: true, default: []
  end
end

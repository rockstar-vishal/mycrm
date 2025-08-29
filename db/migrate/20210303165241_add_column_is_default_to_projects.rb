class AddColumnIsDefaultToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :is_default, :boolean, default: false
  end
end

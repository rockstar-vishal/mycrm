class AddCountryIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :country_id, :integer
  end
end

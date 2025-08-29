class AddProjectIdToMcubeSids < ActiveRecord::Migration
  def change
    add_column :mcube_sids, :project_id, :integer
  end
end

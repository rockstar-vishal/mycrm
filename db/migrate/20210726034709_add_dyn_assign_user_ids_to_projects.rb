class AddDynAssignUserIdsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :dyn_assign_user_ids, :text, default: [], array: true
  end
end

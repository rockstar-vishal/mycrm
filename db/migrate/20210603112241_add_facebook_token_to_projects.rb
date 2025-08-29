class AddFacebookTokenToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :housing_token, :string
  end
end

class AddMbTokenToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :mb_token, :string
    add_column :projects, :nine_token, :string
  end
end

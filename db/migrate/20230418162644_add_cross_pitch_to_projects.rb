class AddCrossPitchToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :cross_pitch, :boolean, default: false
  end
end

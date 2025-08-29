class AddIsCrossPitchToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_cross_pitch, :boolean, default: false
  end
end

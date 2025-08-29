class AddMigrationProjectIdToExotelSids < ActiveRecord::Migration
  def change
    add_column :exotel_sids, :project_id, :integer
  end
end

class AddColumnSourceIdToExotelSids < ActiveRecord::Migration
  def change
    add_column :exotel_sids, :source_id, :integer, index: true
  end
end

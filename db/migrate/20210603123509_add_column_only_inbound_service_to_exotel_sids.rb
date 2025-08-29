class AddColumnOnlyInboundServiceToExotelSids < ActiveRecord::Migration
  def change
    add_column :exotel_sids, :only_inbound_service, :boolean, default: :false
  end
end

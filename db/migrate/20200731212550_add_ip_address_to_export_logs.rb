class AddIpAddressToExportLogs < ActiveRecord::Migration
  def change
    add_column :export_logs, :ip_address, :inet
  end
end

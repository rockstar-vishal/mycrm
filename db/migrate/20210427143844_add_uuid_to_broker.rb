class AddUuidToBroker < ActiveRecord::Migration
  def change
    add_column :brokers, :uuid, :uuid, default: "uuid_generate_v4()"
  end
end

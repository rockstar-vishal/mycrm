class AddColumnIsRoundRobinEnabledToExotel < ActiveRecord::Migration
  def change
    add_column :exotel_sids, :is_round_robin_enabled, :boolean, default: false
  end
end

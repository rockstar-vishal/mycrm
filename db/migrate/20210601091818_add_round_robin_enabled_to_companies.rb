class AddRoundRobinEnabledToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :round_robin_enabled, :boolean, default: false
    add_column :users, :round_robin_enabled, :boolean, default: false
  end
end

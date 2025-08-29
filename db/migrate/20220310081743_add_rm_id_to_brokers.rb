class AddRmIdToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :rm_id, :integer
  end
end

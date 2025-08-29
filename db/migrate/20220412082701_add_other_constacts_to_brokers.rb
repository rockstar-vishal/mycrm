class AddOtherConstactsToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :other_contacts, :string
  end
end

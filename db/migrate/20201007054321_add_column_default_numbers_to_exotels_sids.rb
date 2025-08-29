class AddColumnDefaultNumbersToExotelsSids < ActiveRecord::Migration
  def change
    add_column :exotel_sids, :default_numbers, :text, default: [], array: true
  end
end

class CreateBrokerConfigurations < ActiveRecord::Migration
  def change
    create_table :broker_configurations do |t|
      t.integer "company_id"
      t.text    "required_fields", default: [], array: true
    end
  end
end

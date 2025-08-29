class AddColumnEventsToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :events, :text, array: true, default: []
  end
end

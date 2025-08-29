class AddLoanEnabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :loan_enabled, :boolean, default: false
  end
end

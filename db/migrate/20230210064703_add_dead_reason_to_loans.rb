class AddDeadReasonToLoans < ActiveRecord::Migration
  def change
    add_column :loans, :dead_reason_id, :integer
    add_column :loans, :dead_sub_reason, :text
  end
end

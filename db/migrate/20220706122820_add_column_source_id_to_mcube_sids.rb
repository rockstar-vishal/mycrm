class AddColumnSourceIdToMcubeSids < ActiveRecord::Migration
  def change
    add_column :mcube_sids, :source_id, :integer, index: true
  end
end

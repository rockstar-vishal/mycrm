class CreateCompaniesReasonsSubReasons < ActiveRecord::Migration
  def change
    add_column :leads, :dead_sub_reason, :string
  end
end

class AddTokenDateToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :token_date, :date
  end
end

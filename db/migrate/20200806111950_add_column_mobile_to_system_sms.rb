class AddColumnMobileToSystemSms < ActiveRecord::Migration
  def change
    add_column :system_sms, :mobile, :string
  end
end

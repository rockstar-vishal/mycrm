class AddColumnTemplateIdToSms < ActiveRecord::Migration
  def change
    add_column :system_sms, :template_id, :string
  end
end

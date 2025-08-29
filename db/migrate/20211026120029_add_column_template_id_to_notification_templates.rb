class AddColumnTemplateIdToNotificationTemplates < ActiveRecord::Migration
  def change
    add_column :notification_templates, :template_id, :string
  end
end

class CreateNotificationTemplates < ActiveRecord::Migration
  def change
    create_table :notification_templates do |t|
      t.integer :company_id
      t.string :name
      t.text :body
      t.text :fields, default: [], array: true

      t.timestamps
    end
  end
end

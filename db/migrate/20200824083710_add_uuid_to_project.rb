class AddUuidToProject < ActiveRecord::Migration
  def change
  	add_column :projects, :uuid, :uuid, default: "uuid_generate_v4()"
  	add_column :call_ins, :uuid, :uuid, default: "uuid_generate_v4()"
  	add_column :users, :uuid, :uuid, default: "uuid_generate_v4()"
  	add_column :notification_templates, :uuid, :uuid, default: "uuid_generate_v4()"
  	add_column :companies_api_keys, :uuid, :uuid, default: "uuid_generate_v4()"
  end
end

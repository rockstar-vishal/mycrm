class EnableUuidExtension < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'
    add_column :leads, :uuid, :uuid, default: 'uuid_generate_v4()'
  end
end

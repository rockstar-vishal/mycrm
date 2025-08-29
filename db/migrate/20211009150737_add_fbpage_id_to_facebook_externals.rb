class AddFbpageIdToFacebookExternals < ActiveRecord::Migration
  def change
    add_column :facebook_externals, :fbpage_id, :string
  end
end

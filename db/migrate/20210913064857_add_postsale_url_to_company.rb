class AddPostsaleUrlToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :postsale_url, :string
  end
end

class AddColumnsLogoAndFaviconToCompanies < ActiveRecord::Migration
  def change
    add_attachment :companies, :logo
    add_attachment :companies, :favicon
    add_attachment :companies, :icon
  end
end

class AddBookFormToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :booking_date, :date
    add_attachment :leads, :booking_form
  end
end

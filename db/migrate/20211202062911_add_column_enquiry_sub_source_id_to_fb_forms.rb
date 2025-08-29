class AddColumnEnquirySubSourceIdToFbForms < ActiveRecord::Migration
  def change
    add_column :companies_fb_forms, :enquiry_sub_source_id, :integer
  end
end

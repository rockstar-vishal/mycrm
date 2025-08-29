class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.text :description
      t.string :domain
      t.string :sms_mask
      t.integer :dead_status_id
      t.integer :expected_site_visit_id
      t.integer :booking_done_id
      t.text :popup_fields,                  default: [], array: true
      t.text :allowed_fields,                default: [], array: true
      t.text :index_fields,                  default: [], array: true
      t.text :export_fields,                 default: [], array: true
      t.text :rejection_reasons
      t.boolean :active, default: true
      t.integer :sms_credit, default: 0
      t.boolean :payment_due, default: false

      t.timestamps
    end
  end
end

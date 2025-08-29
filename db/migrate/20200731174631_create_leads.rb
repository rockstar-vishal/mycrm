class CreateLeads < ActiveRecord::Migration
  def change
    create_table :leads do |t|
      t.integer :company_id
      t.date :date
      t.string :name
      t.string :email
      t.string :mobile
      t.text :other_phones
      t.text :other_emails
      t.text :address
      t.string :city
      t.string :state
      t.string :country
      t.integer :budget
      t.integer :source_id
      t.integer :project_id
      t.integer :user_id
      t.datetime :ncd
      t.text :comment
      t.integer :status_id
      t.string :lead_no
      t.date :visit_date
      t.text :visit_comments
      t.integer :call_in_id
      t.string :dead_reason

      t.timestamps
    end
  end
end

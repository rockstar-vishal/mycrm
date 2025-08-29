class NotificationTemplate < ActiveRecord::Base

  belongs_to :company
  validates :name, presence: true, uniqueness: { scope: :company_id,
    message: "Title should be unique" }
  validates :body, presence: true
  before_save :save_fields

  def save_fields
    dynamic_vars = self.body.scan(/\{{.*?\}}/).map{|content| content.gsub(/{{|}}/,'')}
    self.fields = dynamic_vars
  end

  def find_all_fields
    self.fields.flatten!
    fields&.uniq || []
  end

end

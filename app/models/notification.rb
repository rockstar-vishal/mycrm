class Notification < ActiveRecord::Base

  belongs_to :lead
  belongs_to :company
  belongs_to :template, foreign_key: 'notification_template_id', class_name: '::NotificationTemplate'
  before_save :set_parsed_body

  def default_fields_values
    self.field || {}
  end

  def self.load_methods(notification_template)
    notification_template.find_all_fields.each do |method|
      define_method("#{method}=") do |val|
        self.field_will_change!
        self.field = (self.field || {}).merge!({"#{method}" => val})
      end
      define_method("#{method}") do
        default_fields_values.dig("#{method}")
      end
    end
  end

  def parse_template
    Notifications::LiquidMdTemplate.new(
      self.body,
      self.field
    ).render('text')
  end

  def set_parsed_body
    self.body = parse_template
  end

  def send_sms sent_by_id = nil
    if self.lead.mobile.present?
      ss = self.lead.company.system_smses.new(
        messageable: self.lead,
        mobile: self.lead.mobile,
        text: self.body,
        user_id: sent_by_id,
        template_id: self.template&.template_id
      )
      ss.save
    end
  end

end

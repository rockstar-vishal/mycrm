class Broker < ActiveRecord::Base
  include AppSharable
  include PostsaleIntegrationApi

  belongs_to :company
  has_many :leads

  belongs_to :rm, class_name: "::User", foreign_key: :rm_id

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :mobile, length: {maximum: 15}, presence: true
  validates :name, presence: true
  validates_uniqueness_of :email, :mobile, :rera_number, { scope: :company_id,
    message: "Should be unique", allow_blank: true }
  validate :validate_broker_required_fields

  after_commit :broker_integration_to_postsale, on: :create, if: :enable_broker_integration?

  def enable_broker_integration?
    self.company.setting.present? && self.company.setting.biz_integration_enable && self.company.setting.broker_integration_enable
  end

  def validate_broker_required_fields
    if self.company.broker_configuration.present? && self.company.broker_configuration_required_fields.reject(&:empty?).present?
      self.company.broker_configuration_required_fields.reject(&:empty?).each do |field|
        if self.respond_to?(("#{field}".to_sym))
          if self.send("#{field}".to_sym).blank?
            self.errors.add(:base, "#{field.split('_').map(&:capitalize).join(' ')} cant be blank")
          end
        end
      end
    end
  end


  class << self

    def basic_search(search_string)
      all.where("name ILIKE ? OR firm_name ILIKE ? OR mobile ILIKE ? OR email ILIKE ? OR rera_number ILIKE ?", "%#{search_string}%", "%#{search_string}%", "%#{search_string}%", "%#{search_string}%", "%#{search_string}%")
    end

  end

end

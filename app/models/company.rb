class Company < ActiveRecord::Base

  include CustomFields
  include Worker
  include HasMagicFields::Extend
  include OtpGenerator

  has_magic_fields

  EVENTS = ['incoming_call', 'ncd_reminder', 'missed_call', 'lead_create', 'lead_assign']

  has_many :call_ins, dependent: :destroy
  has_many :export_logs, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :users_projects, through: :projects
  has_many :system_smses, class_name: "::SystemSms", dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :leads
  has_many :loans
  has_many :integrations, dependent: :destroy, class_name: "::Companies::Integration"
  has_many :brokers, dependent: :destroy
  has_many :api_keys, class_name: "::Companies::ApiKey", dependent: :destroy
  has_many :company_statuses, :class_name=> "::CompanyStatus", dependent: :destroy
  has_many :company_stages, :class_name=> "::CompanyStage", dependent: :destroy
  has_many :company_stage_statuses, through: :company_stages, source: :company_stage_statuses
  has_many :statuses, through: :company_statuses, :source=>:status
  has_many :company_sources, dependent: :destroy
  has_many :exotel_sids, dependent: :destroy
  has_many :mcube_sids, dependent: :destroy
  has_many :sources, through: :company_sources
  has_many :cp_sources, ->{cp_sources}, through: :company_sources, class_name: '::Source', source: :source
  has_many :digital_sources, ->{digital_sources}, through: :company_sources, class_name: '::Source', source: :source
  has_many :referal_sources, ->{referal_sources}, through: :company_sources, class_name: '::Source', source: :source
  has_many :reasons, :class_name=>"::Companies::Reason", dependent: :destroy
  has_many :mcube_groups, class_name: '::Mcubegroup', dependent: :destroy
  has_many :fb_pages, class_name: "::Companies::FbPage", dependent: :destroy
  has_many :fb_forms, class_name: "::Companies::FbForm", dependent: :destroy
  has_many :call_attempts, class_name: "::CallAttempt", through: :users, foreign_key: :user_id
  has_many :role_statuses, class_name: "::RoleStatus"
  has_many :fb_ads_ids, through: :projects

  has_one :push_notification_setting, class_name: 'PushNotificationSetting', inverse_of: :company
  has_one :setting, class_name: "::Companies::Setting"
  has_one :exotel_integration, -> {for_exotel}, class_name: '::Companies::Integration'
  has_one :mcube_integration, -> {for_mcube}, class_name: '::Companies::Integration'
  has_one :mailchimp_integration, -> {for_mailchimp}, class_name: '::Companies::Integration'
  has_one :sms_integration, -> {sms}, class_name: '::Companies::Integration'
  has_one :default_project, -> {where(is_default: true) }, class_name: '::Project'
  has_one :broker_configuration, class_name: "::BrokerConfiguration"

  validates :name, :domain, presence: true, uniqueness: true
  validates :sms_mask, :default_from_email, :dead_status_ids, :booking_done_id, :reasons, presence: true
  validate :atleast_one_user_for_round_robin, on: :update
  has_many :notification_templates
  has_many :notifications
  has_many :campaigns
  has_many :sub_sources
  has_many :push_notification_logs
  has_many :custom_labels
  has_many :round_robin_settings, through: :users
  has_many :sl_round_robin_users, through: :round_robin_settings, foreign_key: :user_id, class_name: 'User', source: :user

  has_associated_audits

  scope :active, -> { where(:active=>true) }
  default_scope { where.not(:id => 1) }

  delegate :callback_url, :integration_key,:token, :sid, to: :exotel_integration, prefix: true, allow_nil: true
  delegate :callback_url, :integration_key, to: :mcube_integration, prefix: true, allow_nil: true
  delegate :callback_url, :integration_key, to: :bulksms_integration, prefix: true, allow_nil: true
  delegate :required_fields, to: :broker_configuration, prefix: true, allow_nil: true


  ::Companies::Setting::SETTING_BOOLEAN_FIELDS.each do |setting|
    delegate "#{setting}", to: :setting, allow_nil: true
  end

  accepts_nested_attributes_for :fb_pages, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :reasons, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :magic_fields, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :push_notification_setting, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :mcube_groups, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :exotel_integration, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :mailchimp_integration, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :mcube_integration, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :sms_integration, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :setting, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :company_stages, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :role_statuses, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :custom_labels, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :broker_configuration, reject_if: :all_blank, allow_destroy: true

  def can_send_push_notification?
    self.push_notification_setting.present? && self.push_notification_setting.is_active?
  end

  def is_pusher_active?
    self.events.present?
  end


  def mcube_enabled?
    self.mcube_integration.present? && self.mcube_integration.active?
  end

  def exotel_enabled?
    self.exotel_integration.present? && self.exotel_integration.active?
  end

  def atleast_one_user_for_round_robin
    if self.round_robin_enabled? && self.users.round_robin_users.blank?
      self.errors.add(:base, "Atleast one user required for round robin")
      return false
    end
  end

  def status_wise_stage_data
    status_final_array = []
    if self.company_stage_statuses.present?
      status_hash = {}
      status_wise_group_data = self.company_stage_statuses.group_by(&:status_id)
      status_wise_group_data.each do |status|
        status_hash = {status_id: status[0]}
        status_hash["stage_data"] = []
        data_hash = {}
        data_hash_array = []
        status[1].each do |data|
          data_hash = data_hash.merge(
            {
              text: data.company_stage.stage&.name,
              value: data.company_stage.stage&.id
            }
          )
          status_hash["stage_data"].push(data_hash)
        end
        status_final_array.push(status_hash)
      end
    elsif self.company_stages.present?
      self.statuses.each do |status|
        status_hash = {status_id: status.id}
        status_hash["stage_data"] = []
        self.company_stages.each do |stage|
          data_hash_array = []
          data_hash = {}
          data_hash.merge!(
            {
              value: stage.stage_id,
              text: stage.stage&.name
            }
          )
          status_hash["stage_data"].push(data_hash)
        end
        status_final_array.push(status_hash)
      end
    end
    status_final_array
  end

  class << self
    def to_csv(options = {})
      CSV.generate(options) do |csv|
        exportable_fields = ['Company Name', 'Domain', 'On-Boarding Date', 'Last Updated At', 'No of Users']
        exportable_fields = exportable_fields
        csv << exportable_fields

        all.each do |company|
          this_exportable_fields = [company.name, company.domain, company.created_at.strftime("%d-%m-%Y %H:%M %p"), company.updated_at.strftime("%d-%m-%Y %H:%M %p"), company.users.count]
          csv << this_exportable_fields
        end
      end
    end
  end

end

class Lead < ActiveRecord::Base

  include LeadApiAttributes
  include HasMagicFields::Extend
  include LeadRequirements
  include PostsaleIntegrationApi
  include ReportCsv
  include LeadNotifications

  CROSS_PITCH_SOURCE_ID = 17

  audited associated_with: :company, only: [:status_id, :user_id, :comment, :tentative_visit_planned]

  attr_accessor :should_delete, :actual_comment, :reset_comment

  belongs_to :company
  has_magic_fields :through => :company
  has_many :notifications, dependent: :destroy
  has_one :loan, class_name: "::Loan"
  has_many :visits, :class_name=>"::Leads::Visit", dependent: :destroy
  has_many :system_messages, as: :messageable, :class_name=>"::SystemSms", dependent: :destroy
  has_many :emails, as: :receiver, class_name: 'Email', dependent: :destroy
  has_many :call_attempts, dependent: :destroy
  has_many :custom_audits, class_name: "CustomAudit", foreign_key: :auditable_id, dependent: :destroy
  belongs_to :source
  belongs_to :project
  belongs_to :user
  belongs_to :presale_user, class_name: 'User', foreign_key: :presale_user_id
  belongs_to :postsale_user, class_name: 'User', foreign_key: :closing_executive
  belongs_to :status
  belongs_to :call_in
  belongs_to :city
  belongs_to :broker
  belongs_to :enq_subsource, :class_name=> 'SubSource', foreign_key: :enquiry_sub_source_id
  belongs_to :stage
  belongs_to :presales_stage, class_name: 'Stage', foreign_key: :presale_stage_id
  belongs_to :dead_reason, :class_name=>"::Companies::Reason"
  has_many :call_logs, class_name: "Leads::CallLog", dependent: :destroy
  has_many :push_notification_logs, class_name: 'PushNotificationLog', dependent: :destroy
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, :allow_blank => true
  validates :mobile, length: {maximum: 20}, allow_blank: true
  validates :company, :status, :source, :project, presence: true

  validate :check_ncd
  validates :dead_reason, presence: true, if: Proc.new { |a| [a.company.dead_status_ids].include?(a.status_id) }
  validates :lead_no, presence: true, uniqueness: true

  validate :uniqueness_validation, :either_email_or_phone_present
  validate :company_specific_validations
  scope :backlogs_for, -> (company){where("leads.ncd IS NULL OR leads.ncd <= ?", Time.zone.now).active_for(company)}
  scope :todays_calls, -> {where("leads.ncd BETWEEN ? AND ?",Date.today.beginning_of_day, Date.today.end_of_day)}
  scope :active_for, -> (company){where.not(:status_id=>[company.dead_status_ids, company.booking_done_id].flatten)}
  scope :booked_for, -> (company){where(:status_id=>company.booking_done_id)}
  scope :expired, ->{where(lease_expiry_date: Date.today-1.month..Date.today-1)}
  scope :expiring, ->{where(lease_expiry_date: Date.today..Date.today+1.month)}
  scope :site_visit_scheduled, ->{where(is_site_visit_scheduled: true)}

  before_validation :set_lead_no, :set_defaults, on: :create

  delegate :name, to: :project, prefix: true, allow_blank: true

  accepts_nested_attributes_for :visits, reject_if: :all_blank, allow_destroy: true

  after_commit :delete_audit_logs, on: :destroy
  after_commit :client_integration_to_postsale, if: :client_integration_enable?
  before_create :set_executive
  after_create :set_presale_user, if: :presale_user_site_visit_enabled?
  after_commit :notify_lead_create_event, :send_lead_create_brower_notification, on: :create
  before_save :set_site_visit_scheduled
  after_save :set_visit, if: :is_advance_visit_enabled?
  after_commit :create_lead_registration_sms, on: :create
  after_commit :delete_marked_for_deletion, on: :create
  before_create :merge_with_duplicate_lead

  OTHER_DATA = [
    :gclick_id,
    :fb_ads_id
  ]

  def default_fields_values
    self.other_data || {}
  end

  def set_site_visit_scheduled
    if self.tentative_visit_planned.present?
      self.is_site_visit_scheduled = true
    end
  end

  OTHER_DATA.each do |method|
    define_method("#{method}=") do |val|
      self.other_data_will_change!
      self.other_data = (self.other_data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end

  def file_url
    if self.booking_form.present?
      self.booking_form.url
    end
  end

  def uniqueness_validation
    email = self.email&.strip
    phone = self.mobile.to_s&.strip&.gsub(' ', '')
    project_id = self.project_id
    dead_status_ids = self.company.dead_status_ids
    if self.company.setting.present? && self.company.setting.global_validation.present?
      leads = ::Lead.where.not(:id=>self.id).where(:company_id=>self.company_id)
    else
      leads = ::Lead.where.not(:id=>self.id, :status_id=>dead_status_ids).where(:company_id=>self.company_id, :project_id=>project_id)
    end
    leads = leads.where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(REPLACE(mobile,' ', ''), 10) LIKE ?)", email, "#{phone.last(10) if phone.present?}")
    if leads.present?
      if( leads.first.email.present? && leads.first.email == email)
        self.errors.add(:base, "Email should be unique for a particular project for leads in non dead state")
        self.errors.add(:base, "Lead with the same email is assigned to #{leads.first.user.name}")
        return false
      elsif(leads.first.mobile&.strip&.gsub(' ', '').last(10) == phone.last(10))
        self.errors.add(:base, "Mobile number should be unique for a particular project for leads in non dead state")
        self.errors.add(:base, "Lead with the same mobile number is assigned to #{leads.first.user.name}")
        return false
      end
      self.errors.add(:base, "Mobile Number / Email duplicate")
      return false
    end
  end

  def either_email_or_phone_present
    if %w(email mobile).all?{|attr| self[attr].blank?}
      errors.add :base, "Either Phone or Email should be present"
      return false
    end
  end

  def set_defaults
    self.company_id = (self.user.company_id rescue nil) if self.company_id.blank?
    self.status_id = (self.company.new_status_id rescue nil) if self.status_id.blank?
    self.date = Date.today if self.date.blank?
    self.project_id = self.company.default_project&.id if self.project_id.blank?
  end

  def status_id=(input_status_id)
    super
    if self.company.present? && input_status_id.present?
      if input_status_id.to_i == self.company.booking_done_id
        self.conversion_date=::Date.today
      else
        self.conversion_date=nil
      end
    end
  end

  def source_with_call_in
    if self.source_id == ::Source::INCOMING_CALL && self.call_in.present?
      return "#{self.source.name} (#{self.formatted_subsource})"
    elsif self.source.is_cp? && self.broker.present?
      return "#{self.source&.name} (#{self.broker&.name})"
    elsif self.source.is_reference && self.referal_name.present? || self.referal_mobile.present?
      return "#{self.source&.name} (#{self.referal_name} #{self.referal_mobile})"
    else
      return self.source.name rescue nil
    end
  end

  def formatted_subsource
    if self.sub_source.present?
      self.sub_source
    elsif self.enq_subsource.present?
      self.enq_subsource&.name
    else
      self.sub_source
    end
  end

  def set_lead_no
    self.lead_no = generate_uniq_lead_no
  end

  def is_advance_visit_enabled?
    self.company.setting.present? && self.company.enable_advance_visits
  end

  def set_visit
    if self.status_id == self.company.expected_site_visit_id && self.changes.present? && self.changes["tentative_visit_planned"].present?
      visit_date = self.tentative_visit_planned if self.tentative_visit_planned.present?
      self.visits.create(date: visit_date.to_date) if visit_date.present?
    end
  end

  def create_lead_registration_sms
    if self.user.company.mobicomm_sms_service_enabled
      if self.mobile.present?
        ss = self.company.system_smses.new(
          messageable_id: self.id,
          messageable_type: "Lead",
          mobile: self.mobile,
          text: "Dear #{self.name}, Thank you for showing interest in our project #{self.project_name}. Our Sales Representative #{self.user&.name}(#{self&.user&.mobile}) shall be in touch with you. In the meantime, please visit #{self.project_name} to know more details about the project. \nRegards, \nTeam #{self.project_name}",
          user_id: self.user.id
        )
        ss.save
      end
    end
  end

  def is_dead?
    return self.company.dead_status_ids.include?(self.status_id.to_s)
  end

  def is_booked?
    return self.status_id == self.company.booking_done_id
  end

  def client_integration_enable?
    self.company.setting.client_integration_enable
  end

  def presale_user_site_visit_enabled?
    self.company.enable_presale_user_visits_report
  end

  def set_presale_user
    self.update_attributes(presale_user_id: self.user_id)
  end

  def is_ncd_required?
    if self.company.is_required_fields?("ncd")
      inactive_status_ids = self.company.dead_status_ids << self.company.booking_done_id.to_s
      self.company.setting.present? && self.company.set_ncd_non_mandatory_for_booked_status && inactive_status_ids.reject(&:blank?).include?(self&.status_id.to_s) ? false : true
    else
      return false
    end
  end


  def notify_lead_create_event
    if self.company.events.include?("lead_create")
      url = "http://#{self.company.domain}/leads/#{self.id}/edit"
      message_text = "Lead #{self.name}, assigned to #{self.user&.name} has been created at #{self.created_at.strftime('%d-%b-%y %H:%M %p')}. <a href=#{url} target='_blank'>click here</a>"
      Pusher.trigger(self.company.uuid, 'lead_create', {message: message_text, notifiables: [self.user.uuid]})
    end
  end

  def send_lead_create_brower_notification
    if self.company.push_notification_setting.present? && self.company.push_notification_setting.is_active? && self.company.events.include?('lead_create')
      Resque.enqueue(::ProcessMobilePushNotification, self.id)
    end
  end

  def city_localities
    Locality.joins(region: [:city]).where("cities.id=?", self.city_id)
  end

  def merge_with_duplicate_lead
    if self.company.open_closed_lead_enabled
      email = self.email
      phone = self.mobile
      leads = self.company.leads.where.not(:id=>self.id).where(project_id: self.project_id, status_id: self.company.dead_status_ids).where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(mobile, 10) ILIKE ?)", email, "#{phone.last(10) if phone.present?}")
      if leads.present?
        original_lead = leads.last
        status, message = original_lead.merge_lead_obj self
        self.should_delete = true
      end
      return true
    end
  end

  def merge_lead_obj deletable_lead
    self.actual_comment = "#{self.comment} #{self.company.open_closed_lead_enabled && self.is_dead? ? '[RE-ENQUIRED]' : '[MERGE]'} #{deletable_lead.comment}"
    self.other_phones = "#{deletable_lead.mobile} / #{deletable_lead.other_phones}"
    self.other_emails = "#{deletable_lead.email} / #{deletable_lead.other_emails}"
    self.project_id = deletable_lead.project_id
    self.source_id = deletable_lead.source_id
    if self.company.open_closed_lead_enabled && self.is_dead?
      self.status_id = self.company.new_status_id
    end
    if self.save
      return true, "Success"
    else
      return false, "Cannot merge lead - #{self.errors.full_messages.join(', ')}"
    end
  end

  class << self
    def current_user=(user)
      RequestStore.store[:current_user] = user
    end

    def current_user
      RequestStore.store[:current_user]
    end

    def search_base_leads(user)
      return user.manageable_leads
    end

    def user_leads(user)
      leads = user.manageable_leads.active_for(user.company)
      return leads
    end

    def site_visit_planned_leads(user)
      leads = user.manageable_leads.where("leads.status_id = ?", user.company.expected_site_visit_id)
      return leads
    end

    def basic_search(search_string, user)
      leads = all.where("leads.email ILIKE :term OR leads.mobile LIKE :term OR leads.name ILIKE :term OR leads.lead_no ILIKE :term", :term=>"%#{search_string}%")
    end

    def filter_leads_for_reports(params, user)
      leads = all
      if params[:updated_from].present?
        updated_from = Time.zone.parse(params[:updated_from]).at_beginning_of_day
        leads = leads.where("leads.updated_at >= ?", updated_from)
      end
      if params[:updated_upto].present?
        updated_upto = Time.zone.parse(params[:updated_upto]).at_end_of_day
        leads = leads.where("leads.updated_at <= ?", updated_upto)
      end
      if params[:project_ids].present?
        leads = leads.where(:project_id=>params[:project_ids])
      end
      if params[:source_ids].present?
        leads = leads.where(:source_id=>params[:source_ids])
      end
      if params[:manager_id].present?
        manageables = user.manageables.find_by_id(params[:manager_id]).subordinates.ids
        leads = leads.where(:user_id=>manageables)
      end
      if params[:user_ids].present?
        leads = leads.where(:user_id=>params[:user_ids])
      end
      if params[:sub_source_ids].present?
        leads=leads.where(enquiry_sub_source_id: params[:sub_source_ids])
      end
      if params[:customer_type].present?
        leads = leads.where(:customer_type=>params[:customer_type])
      end
      if params[:booking_date_from].present?
        booked_id = user.company.booking_done_id
        booking_date_from = Date.parse(params[:booking_date_from])
        leads = leads.where("status_id = ? AND booking_date >= ?",booked_id, booking_date_from)
      end
      if params[:booking_date_to].present?
        booked_id = user.company.booking_done_id
        booking_date_to = Date.parse(params[:booking_date_to])
        leads = leads.where("status_id= ? AND booking_date <= ?",booked_id, booking_date_to)
      end
      if params[:site_visit_from].present?
        site_visit_from = Time.zone.parse(params[:site_visit_from]).at_beginning_of_day
        leads = leads.where("tentative_visit_planned >= ?", site_visit_from)
      end
      if params[:site_visit_upto].present?
        site_visit_upto = Time.zone.parse(params[:site_visit_upto]).at_beginning_of_day
        leads = leads.where("tentative_visit_planned <= ?", site_visit_upto)
      end
      return leads
    end

    def advance_search(search_params, user)
      leads = all
      if search_params["ncd_from"].present?
        next_call_date_from = Time.zone.parse(search_params["ncd_from"]).at_beginning_of_day
      end
      if search_params["ncd_upto"].present?
        next_call_date_upto = Time.zone.parse(search_params["ncd_upto"]).at_end_of_day
      end
      if search_params["exact_ncd_from"].present?
        exact_next_call_date_from = Time.zone.at(search_params["exact_ncd_from"].to_i)
      end
      if search_params["exact_ncd_upto"].present?
        exact_next_call_date_upto = Time.zone.at(search_params["exact_ncd_upto"].to_i)
      end
      if search_params["created_at_from"].present?
        created_at_from = Time.zone.parse(search_params["created_at_from"]).at_beginning_of_day
      end
      if search_params["created_at_upto"].present?
        created_at_upto = Time.zone.parse(search_params["created_at_upto"]).at_end_of_day
      end
      if search_params["visited_date_from"].present?
        visited_date_from = Date.parse(search_params["visited_date_from"])
      end
      if search_params["visited_date_upto"].present?
        visited_date_upto = Date.parse(search_params["visited_date_upto"])
      end
      if search_params["token_date_from"].present?
        token_date_from = Date.parse(search_params["token_date_from"])
      end
      if search_params["token_date_to"].present?
        token_date_to = Date.parse(search_params["token_date_to"])
      end
      if search_params["booking_date_from"].present?
        booking_date_from = Date.parse(search_params["booking_date_from"])
      end
      if search_params["booking_date_to"].present?
        booking_date_to = Date.parse(search_params["booking_date_to"])
      end
      if search_params["assigned_to"].present?
        leads = leads.where(:user_id=>search_params["assigned_to"])
      end
      if search_params["presale_user_id"].present?
        leads = leads.where(:presale_user_id=>search_params["presale_user_id"])
      end
      if search_params["manager_id"].present?
        searchable_users = user.manageables.find_by(id: search_params["manager_id"]).subordinates.ids
        leads = leads.where(:user_id=>searchable_users)
      end
      if search_params["closing_executive"].present?
        leads = leads.where(:closing_executive=>search_params["closing_executive"])
      end
      if search_params["lead_no"].present?
        leads = leads.where(:lead_no=>search_params["lead_no"] )
      end
      if search_params["name"].present?
        leads = leads.where("leads.name ILIKE ?", "%#{search_params["name"]}%")
      end
      if search_params["lead_statuses"].present?
        leads = leads.where(:status_id=>search_params["lead_statuses"] )
      end
      if search_params["dead_reasons"].present?
        dead_reason_ids = user.company.dead_status_ids
        leads = leads.where(status_id: dead_reason_ids, dead_reason_id: search_params["dead_reasons"])
      end
      if token_date_from.present?
        token_ids = user.company.token_status_ids.reject(&:blank?)
        leads = leads.where("status_id = ? AND token_date >= ?",token_ids, token_date_from)
      end
      if token_date_to.present?
        token_ids = user.company.token_status_ids.reject(&:blank?)
        leads = leads.where("status_id = ? AND token_date <= ?",token_ids, token_date_to)
      end
      if booking_date_from.present?
        booked_id = user.company.booking_done_id
        leads = leads.where("status_id = ? AND booking_date >= ?",booked_id, booking_date_from)
      end
      if booking_date_to.present?
        booked_id = user.company.booking_done_id
        leads = leads.where("status_id = ? AND booking_date <= ?",booked_id, booking_date_to)
      end
      if search_params["budget_from"].present?
        leads = leads.where("leads.budget >= ?", search_params["budget_from"] )
      end
      if search_params["budget_upto"].present?
        leads = leads.where("leads.budget <= ?", search_params["budget_upto"] )
      end
      if next_call_date_from.present?
        leads = leads.where("leads.ncd >= ?", next_call_date_from)
      end
      if next_call_date_upto.present?
        leads = leads.where("leads.ncd <= ?", next_call_date_upto)
      end
      if exact_next_call_date_from.present?
        leads = leads.where("leads.ncd >= ?", exact_next_call_date_from)
      end
      if exact_next_call_date_upto.present?
        leads = leads.where("leads.ncd <= ?", exact_next_call_date_upto)
      end
      if created_at_from.present?
        leads = leads.where("leads.created_at >= ?", created_at_from)
      end
      if created_at_upto.present?
        leads = leads.where("leads.created_at <= ?", created_at_upto)
      end
      if search_params["visited"].present? && search_params["visited"] == "true"
        leads = leads.joins{visits}
      end

      if search_params["email"].present?
        leads = leads.where("leads.email ILIKE ?", "%#{search_params["email"]}%" )
      end
      if search_params["mobile"].present?
        leads = leads.where("leads.mobile ILIKE ?", "%#{search_params["mobile"]}%" )
      end
      if search_params["other_phones"].present?
        leads = leads.where("leads.other_phones ILIKE ?", "%#{search_params["other_phones"]}%" )
      end
      if search_params["project_ids"].present?
        if user.company.is_sv_project_enabled
          leads = leads.includes(visits: :visits_projects).references(:leads_visits_projects).where("leads.project_id IN (?) or leads_visits_projects.project_id IN (?)", search_params["project_ids"], search_params["project_ids"])
        else
          leads = leads.where(project_id: search_params["project_ids"])
        end
      end
      if search_params[:sv_user].present?
        leads = leads.joins{visits}.where(visits: {user_id: search_params[:sv_user]})
      end
      if search_params["backlogs_only"].present?
        leads = leads.backlogs_for(user.company)
      end
      if search_params["todays_call_only"].present?
        leads = leads.active_for(user.company).todays_calls
      end
      if search_params["comment"].present?
        leads = leads.where("leads.comment ILIKE ?", "%#{search_params["comment"]}%")
      end
      if search_params[:dead_reason_ids].present?
        leads = leads.where(:dead_reason_id=>search_params[:dead_reason_ids])
      end
      if search_params["source_id"].present?
        leads = leads.where(:source_id=> search_params["source_id"])
      end
      if search_params["source_ids"].present?
        leads = leads.where(:source_id=>search_params["source_ids"])
      end
      if search_params["sub_source"].present?
        leads = leads.where(:sub_source=>search_params["sub_source"])
      end
      if search_params["sub_source_ids"].present?
        leads = leads.where(enquiry_sub_source_id: search_params["sub_source_ids"])
      end
      if search_params["stage_ids"].present?
        leads = leads.where(presale_stage_id: search_params["stage_ids"])
      end
      if search_params["city_ids"].present?
        leads = leads.where(:city_id=>search_params["city_ids"])
      end
      if search_params["country_ids"].present?
        leads = leads.joins{project}.where("projects.country_id IN (?)", search_params["country_ids"])
      end
      if search_params["lead_ids"].present?
        leads = leads.where(:id=>search_params["lead_ids"])
      end
      if search_params["customer_type"].present?
        leads = leads.where(customer_type: search_params["customer_type"])
      end
      if search_params["state"].present?
        leads = leads.where("leads.state ILIKE ?", "%#{search_params["state"]}%")
      end
      if search_params["visit_counts"].present?
        if search_params["visit_counts"] == "Revisit"
          leads=leads.where(revisit: true)
        else
          leads =leads.where(revisit: false)
        end
      end
      if visited_date_from.present?
        if user.company.enable_advance_visits
          leads = leads.joins{visits}.where("leads_visits.is_visit_executed = ? AND leads_visits.date >= ?", true, visited_date_from)
        else
          leads = leads.joins{visits}.where("leads_visits.date >= ?", visited_date_from)
        end
      end
      if visited_date_upto.present?
        if user.company.enable_advance_visits
          leads = leads.joins{visits}.where("leads_visits.is_visit_executed = ? AND leads_visits.date <= ?", true, visited_date_upto)
        else
          leads = leads.joins{visits}.where("leads_visits.date <= ?", visited_date_upto)
        end
      end
      if search_params["expired_from"].present?
        expired_from = Date.parse(search_params["expired_from"])
      end
      if expired_from.present?
        leads = leads.where("lease_expiry_date >= ?", expired_from)
      end
      if search_params["expired_upto"].present?
        expired_upto = Date.parse(search_params["expired_upto"])
      end
      if expired_upto.present?
        leads = leads.where("lease_expiry_date < ?", expired_upto)
      end
      if search_params["lead_stages"].present?
        leads = leads.where(presale_stage_id: search_params["lead_stages"])
      end
      if search_params["site_visit_from"].present?
        site_visit_from = Time.zone.parse(search_params["site_visit_from"]).at_beginning_of_day
        leads = leads.where("tentative_visit_planned >= ?", site_visit_from)
      end
      if search_params["site_visit_upto"].present?
        site_visit_upto = Time.zone.parse(search_params["site_visit_upto"]).at_beginning_of_day
        leads = leads.where("tentative_visit_planned <= ?", site_visit_upto)
      end
      if search_params["site_visit_planned"].present?
        leads = leads.site_visit_scheduled
      end
      if search_params["revisit"].present?
        leads = leads.site_visit_scheduled.where(revisit: true)
      end
      if search_params["booked_leads"].present?
        leads = leads.site_visit_scheduled.booked_for(current_user.company)
      end
      if search_params["token_leads"].present?
        if user.company.token_status_ids.reject(&:blank?).present?
          leads = leads.where(status_id: user.company.token_status_ids)
        end
      end
      if search_params["postponed"].present?
        leads = leads.joins{visits}.where("leads_visits.is_postponed='t'")
      end
      if search_params["visit_cancel"].present?
        leads = leads.joins{visits}.where("leads_visits.is_canceled='t'")
      end
      if search_params["site_visit_done"].present?
        leads = leads.joins{visits}.where(visits: {is_visit_executed: true})
      end
      leads = leads.includes(:magic_attributes).references(:magic_attributes)
      user.company.magic_fields.each do |field|
        if search_params["#{field.name}"].present?
          if field.datatype == 'string'
            leads = leads.where("magic_attributes.magic_field_id = ? AND value ILIKE ?", field.id, "%#{search_params["#{field.name}"]}%")
          elsif field.datatype == 'integer'
            leads = leads.where("magic_attributes.magic_field_id = ? AND value = ?", field.id, search_params["#{field.name}"])
          end
        end
      end
      return leads
    end

    def to_csv(options = {}, exporting_user, ip_address, leads_count)
      exporting_user.company.export_logs.create(user_id: exporting_user.id, ip_address: ip_address, count: leads_count)
      CSV.generate(options) do |csv|
        exportable_fields = ['Customer Name', 'Lead Number', 'Project', 'Assigned To', 'Lead Status', 'Presale Stage', 'Next Call Date', 'Comment', 'Source','Broker', 'Visited', 'Visited Date', 'Dead Reason', 'Dead Sub Reason', 'City', 'Created At', 'Sub Source']
        exportable_fields = exportable_fields | exporting_user.company.magic_fields.pluck(:pretty_name)
        if exporting_user.is_super? || exporting_user.is_sl_admin?
          exportable_fields << 'Mobile'
          exportable_fields << 'Email'
        end
        if exporting_user.company.is_allowed_field?("customer_type")
          exportable_fields << 'Customer Type'
        end
        exportable_fields << 'Tentative Visit Date'
        exportable_fields << 'Tentative Visit Day'
        exportable_fields << 'Tentative Visit Time'
        if exporting_user.company.fb_ads_ids.present?
          exportable_fields << 'Facebook Ads Id'
        end
        csv << exportable_fields

        all.includes{project.city}.each do |client|
          dead_reason = ""
          dead_sub_reason = ""
          if exporting_user.company.dead_status_ids.include?(client.status_id.to_s)
            dead_reason = client.dead_reason&.reason
            dead_sub_reason = client.dead_sub_reason
          end
          final_phone = client.mobile
          final_email = client.email
          final_source =(client.source.name rescue "-")
          if client.company.cp_sources.ids.include?(client.source_id)
            final_broker = client.broker.name rescue "-"
          end

          this_exportable_fields = [ client.name, client.lead_no, (client.project.name rescue '-'),(client.user.name rescue '-'), client.status.name, (client.presales_stage&.name rescue '-'), (client.ncd.strftime("%d %B %Y") rescue nil), client.comment, final_source, final_broker, (client.visits.present? ? "Yes" : "No"), (client.visits.collect{ |x| x.date}.join(',') rescue "-"), dead_reason, dead_sub_reason, (client.project.city.name rescue "-"), (client.created_at.in_time_zone.strftime("%d %B %Y : %I.%M %p") rescue nil), client.formatted_subsource]
          exporting_user.company.magic_fields.each do |field|
            this_exportable_fields << client.send(field.name)
          end
          if exporting_user.is_super? || exporting_user.is_sl_admin?
            this_exportable_fields << final_phone
            this_exportable_fields << final_email
          end
          if exporting_user.company.is_allowed_field?("customer_type")
            this_exportable_fields << client.customer_type
          end
          this_exportable_fields << client.tentative_visit_planned&.strftime("%d-%m-%Y")
          this_exportable_fields << client.tentative_visit_planned&.strftime("%A")
          this_exportable_fields << client.tentative_visit_planned&.strftime("%I:%M %p")

          if exporting_user.company.fb_ads_ids.present?
            this_exportable_fields << client.fb_ads_id
          end
          csv << this_exportable_fields
        end
      end
    end

    def save_search_history(search_params, user, search_name)
      user.search_histories.create(
        name: search_name,
        search_params: search_params
      )
    end


    def ncd_not_update_till_thirty_minutes(company)
      leads = all.active_for(company).where("leads.ncd < ?", Time.zone.now - 30.minutes)
      return leads
    end

    def initiate_bulk_call(user)
      request_array = []
      all.each do |lead|
        request_array << {"camp_name": "Fashion_TV", "mobile": "#{lead.mobile&.last(10)}", "agent_id"=> "#{user.agent_id}", "uniqueid"=> "#{lead.id}"}
      end
      begin
        url = "http://czadmin.c-zentrixcloud.com/apps/addlead_bulk.php"
        response = RestClient.post(url, request_array.to_json)
        true
      rescue => e
        false
      end
    end


  end

  def comment=(default_value)
    if default_value.present?
      comment = "#{self.comment_was} \n #{Time.zone.now.strftime("%d-%m-%y %H:%M %p")} (#{(Lead.current_user.name rescue nil)}) : #{default_value}"
      write_attribute(:comment, comment)
    end
  end

  def actual_comment=(default_value)
    if default_value.present?
      write_attribute(:comment, default_value.strip)
    end
  end

  def reset_comment
    write_attribute(:comment, nil)
  end

  def check_ncd
    if self.company.back_dated_ncd_allowed && self.changes.present? && self.changes["ncd"].present?
      if self.changes["ncd"][1].present? && Time.zone.now > self.changes["ncd"][1]
        errors.add(:ncd, 'back dated ncd is not allowed')
      end
    end
  end

  def company_specific_validations
    if self.company_id == 3
      if self.mobile.present? && self.mobile.length < 10
        errors.add(:mobile, "Cannot be less than 10 characters")
      end
    end
  end

  def is_phone_number_valid?
    TelephoneNumber.parse(self.mobile, :in)&.valid?
  end

  def make_call(current_user)
    if current_user.mcube_sid&.is_active?
      self.make_mcube_call(current_user)
    elsif current_user.agent_id.present?
      self.make_czentrixcloud_call(current_user)
    elsif current_user.company.way_to_voice_enabled
      self.make_way_to_voice_call(current_user)
    else
      option = {
        From: current_user.mobile,
        To: self.mobile,
        CallerId: current_user.exotel_sid.number,
        StatusCallback: current_user.company.exotel_integration_callback_url,
        "StatusCallbackEvents[0]"=> 'terminal'
      }
      begin
        url = "https://#{current_user.company.exotel_integration_integration_key}:#{current_user.company.exotel_integration_token}@api.exotel.com/v1/Accounts/#{current_user.company.exotel_integration_sid}/Calls/connect.json"
        response = ExotelSao.secure_post(url, option)
        response = response["Call"]
        call_logs = self.call_logs.build(
          caller: 'User',
          direction: response["Direction"],
          sid: response["Sid"],
          start_time: response["StartTime"],
          to_number: response["To"],
          from_number: response["From"],
          status: response["Status"],
          user_id: current_user&.id
        )
        call_logs.save
      rescue => e
        false
      end
    end

  end

  def make_mcube_call(current_user)
    begin
      url = "https://mcube.vmc.in/api/outboundcall?apikey=#{current_user.company.mcube_integration_integration_key}&exenumber=#{current_user.mobile}&custnumber=#{self.mobile&.last(10)}&did=#{current_user.mcube_sid.number}&url=#{current_user.company.mcube_integration_callback_url}"
      response = McubeSao.secure_get(url)
      call_logs = self.call_logs.build(
        caller: 'User',
        phone_number_sid: current_user.mcube_sid.number,
        direction: 'outgoing',
        sid: response["callid"],
        start_time: Time.now.in_time_zone,
        to_number: self.mobile&.last(10),
        from_number: current_user.mobile,
        user_id: current_user&.id,
        third_party_id: 'mcube'
      )
      call_logs.save
    rescue => e
      false
    end
  end

  def make_way_to_voice_call(current_user)
    begin
      radom_reference_no = SecureRandom.uuid
      url = "https://way2voice.in:444/FileApi/OBDCall?key=3214&userid=ckpl&password=ckpl@123&CallerNo=#{self.mobile.last(10)}&AgentNo=#{self.user.mobile}&refid=#{radom_reference_no}"
      status, code, response = HTTPSao.secure_get(url)
      call_logs = self.call_logs.build(
        caller: 'User',
        phone_number_sid: '07127135984',
        direction: 'outgoing',
        sid: radom_reference_no,
        start_time: Time.now.in_time_zone,
        to_number: self.mobile,
        from_number: current_user.mobile,
        user_id: current_user&.id,
        third_party_id: 'way2voice'
      )
      call_logs.save
    rescue => e
      false
    end
  end

  def make_czentrixcloud_call(current_user)
    begin
      url = "https://admin.c-zentrixcloud.com/apps/appsHandler.php?transaction_id=CTI_DIAL&agent_id=#{current_user.agent_id}&phone_num=#{self.mobile&.last(10)}&resFormat=3&uniqueid=#{self.id}"
      response = McubeSao.secure_get(url)
      response = response["response"] rescue ""
      if response.present?
        response["status"] == "SUCCESS"
      end
    rescue => e
      false
    end
  end

  def magic_field_values
    field_attributes = []
    self.company.magic_fields.each do |field|
      field_attributes.push({
        key: "#{field.name}",
        value: self.send("#{field.name}"),
        datatype: field.datatype,
        label_name: field.pretty_name,
        is_select_list: field.is_select_list,
        items: field.items
      })
    end
    field_attributes
  end

  def is_repeated_call?
    self.call_logs.answered.count > 1
  end

  def delete_marked_for_deletion
    if self.should_delete
      self.should_delete = false
      self.destroy
    end
    return true
  end

  def ctoc_enabled
    current_user = Lead.current_user
    if current_user.present?
      self.is_phone_number_valid? && current_user.click_to_call_enabled? && current_user.sid_active? && current_user.mobile.present?
    end
  end

  def selectable_company_stages
    if self.persisted?
      if self.company.company_stage_statuses.present?
        self.company.company_stages.joins{:company_stage_statuses}.where(company_stage_statuses: {status_id: self.status_id})
      else
        self.company.company_stages
      end
    else
      self.company.company_stages
    end
  end

  def generate_uniq_ssid
    uuid = SecureRandom.uuid
    return uuid if Leads::CallLog.find_by_sid(uuid).blank?
    return self.generate_uniq_ssid
  end

  private
    def generate_uniq_lead_no
      string = "LEA#{rand.to_s[2..7]}"
      return string if check_uniqueness_of_lead_no string
      return generate_uniq_lead_no
    end


    def check_uniqueness_of_lead_no enquiry_no
      return !self.class.find_by_lead_no(enquiry_no).present?
    end

    def delete_audit_logs
      audits.destroy_all
    end

    def set_executive
      company = self.company.reload
      if company.round_robin_enabled?
        if self.user.blank? || self.user.is_super?
          if company.project_wise_round_robin
            project_round_robin_ids = self.project.dyn_assign_user_ids
            user_ids = company.users.round_robin_users.where(id: project_round_robin_ids).ids
            lead_user_id = company.leads.where(project_id: self.project_id).last&.user_id
          elsif company.secondary_level_round_robin
            ss_level_ids = company.round_robin_settings.where(project_id: self.project_id, source_id: self.source_id, sub_source_id: self.enquiry_sub_source_id).pluck(:user_id).uniq
            user_ids = company.users.round_robin_users.where(id: ss_level_ids).ids
            lead_user_id = company.leads.where(project_id: self.project_id, source_id: self.source_id, enquiry_sub_source_id: self.enquiry_sub_source_id).last&.user_id
          else
            lead_user_id = company.leads.last&.user_id
            user_ids = company.users.round_robin_users.ids
          end
          if user_ids.include? lead_user_id
            user_ids.each_with_index do |u, index|
              if(lead_user_id == u)
                if(index == user_ids.size - 1)
                  self.user_id = user_ids[0]
                else
                  self.user_id = user_ids[index+1]
                  break
                end
              end
            end
          else
            self.user_id = user_ids[0] || company.users.active.superadmins.first.id
          end
        end
      else
        self.user_id = company.users.active.superadmins.first.id if self.user_id.blank?
      end
    end
end

class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable
  has_many :export_logs
  has_many :tokens, :class_name=>"Users::Token", dependent: :destroy
  belongs_to :company
  belongs_to :role
  has_many :leads
  has_many :sent_emails, as: :sender, class_name: 'Email'
  has_many :emails, as: :receiver, class_name: 'Email'
  has_many :call_attempts
  has_many :call_logs, class_name: "::Leads::CallLog"
  belongs_to :exotel_sid
  belongs_to :mcube_sid

  has_many :manager_mappings, class_name: "::Users::Manager", foreign_key: :user_id
  has_many :managers, through: :manager_mappings, source: :manager
  has_many :round_robin_settings, class_name: 'RoundRobinSetting'
  has_many :role_statuses, foreign_key: :role_id, primary_key: :role_id, class_name: 'RoleStatus'

  has_many :search_histories, class_name: "::Users::SearchHistory"
  has_many :users_projects, class_name: '::UsersProject'

  has_many :subordinate_mappings, class_name: "::Users::Manager", foreign_key: :manager_id
  has_many :subordinates, through: :subordinate_mappings, source: :user

  belongs_to :city

  validates :name, :mobile, :role, :email, :company, presence: true
  validates :password, confirmation: true


  validate :atleast_one_user_with_round_robin

  before_destroy :check_if_leads_present

  accepts_nested_attributes_for :manager_mappings, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :search_histories, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :round_robin_settings, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :users_projects, reject_if: :all_blank, allow_destroy: true

  has_attached_file :image,
                    path: ":rails_root/public/system/:attachment/:id/:style/:filename",
                    url: "/system/:attachment/:id/:style/:filename"
  validates_attachment_content_type  :image,
                    content_type: ['image/jpeg', 'image/png'],
                    size: { in: 0..2.megabytes }

  scope :active, -> { where(:active=>true) }
  scope :superadmins, -> { where(:role_id=>2)}
  scope :loan_enabled, -> { where(:loan_enabled=>true)}
  scope :managers, -> { where(:role_id=>3)}
  scope :meeting_executives, -> {where(is_meeting_executive: true)}
  scope :calling_executives, -> {where(is_calling_executive: true)}
  scope :managers_role, -> { where(:role_id=>3)}
  scope :round_robin_users, -> { active.where(:round_robin_enabled=>true)}
  scope :cross_pitch_only, -> { where(:is_cross_pitch=>true)}

  def img_url
    if self.image.present?
      self.image.url
    end
  end

  def numbers_with_name
    "#{self.mobile}(#{self.name})"
  end

  def is_super?
    return self.role_id == 2
  end

  def is_sysad?
    return self.role_id == 1
  end

  def is_manager?
    return self.role_id == 3
  end

  def is_executive?
    return self.role_id == 4 || self.role_id == 9
  end

  def is_telecaller?
    return self.role.name == "Telecaller"
  end

  def is_sl_admin?
    return self.role.name == "Secondary Level Admin"
  end

  def can_access_presale?
    self.is_super? || !self.is_meeting_executive? || !self.is_executive?
  end

  def can_access_postsale?
    self.is_super? || self.is_meeting_executive?
  end

  def is_supervisor?
    return self.role.name == "Supervisor"
  end

  def manageables
    return self.company.users if self.is_super?
    user_manageables = self.class.get_manageables [self]
    return self.company.users.where(:id=>user_manageables.map(&:id))
  end

  def manageable_ids
    return self.manageables.ids
  end

  def manageable_leads
    return self.company.leads if self.is_super?
    return self.company.leads.where("leads.user_id IN (:user_ids) OR leads.closing_executive IN (:user_ids)",:user_ids=> self.manageable_ids)
  end

  def manageable_loans
    return self.company.loans if self.is_super?
    return self.company.loans.where("loans.user_id IN (:user_ids)",:user_ids=> self.manageable_ids)
  end

  def check_source_presence
    (self.company.setting.present? && self.company.enable_source) ? self.is_super? : true
  end

  def check_if_leads_present
    if self.leads.present?
      self.errors.add(:base, "Please reassign the leads of this user before deleting")
      return false
    end
  end

  def atleast_one_user_with_round_robin
    if self.company.present? && self.company.round_robin_enabled? && self.company.users.where.not(:id=>self.id).round_robin_users.blank? && self.round_robin_enabled.blank?
      self.errors.add(:base, "Atleast one user should have round robin enabled")
      return false
    end
  end

  def accessible_roles
    if self.is_sysad?
      Role.all
    else
      other_role_ids =  ::Role.where.not(id: ::Role::IDS_ORDER).pluck(:id)
      order_ids = ::Role::IDS_ORDER | other_role_ids
      Role.where.not(id: Role::SYSTEM_ADMIN_ROLE).for_ids_with_order(order_ids)
    end
  end

  def statuses_roles
    return self.company.statuses if self.is_super?
    role_statuses = self.role_statuses.where(company_id: self.company_id)
    if role_statuses.present?
      self.company.statuses.where(id: role_statuses.pluck(:status_ids).flatten!)
    else
      self.company.statuses
    end
  end

  def active_for_authentication?
    super and self.active?
  end

  class << self
    def get_manageables users
      final_list = users
      con_users = users
      while true
        s_list = get_subordinates_list con_users
        break if s_list.blank?
        final_list = final_list | s_list
        con_users = s_list
        get_subordinates_list s_list
      end
      return final_list
    end

    def get_subordinates_list user_arr
      to_send_data = []
      user_arr.each do |user|
        to_send_data << user.subordinates
      end
      return to_send_data.flatten.compact.uniq
    end

    def identify_from_phone phone
      return nil if phone.blank?
      final_phone = phone.gsub("+91", "")
      user = all.where("users.mobile LIKE ?", "%#{final_phone}%").last
      return (user.id rescue nil)
    end

    def ncd_in_next_fifteen_minutes(company)
      ranged_leads = company.leads.where(ncd: Time.zone.now+15.minutes..Time.zone.now+30.minutes)
      company.users.where(id: ranged_leads.joins(:user).pluck(:user_id))
    end

    def send_push_notifications(company)
      url = "http://#{company.domain}/leads?is_advanced_search=true&exact_ncd_from=#{(Time.zone.now+15.minutes).to_i}&exact_ncd_upto=#{(Time.zone.now+30.minutes).to_i}"
      message_text = "Reminder To Call Leads. Next Call In 30 Mins. <a href=#{url} target='_blank'>click here</a>"
      Pusher.trigger(company.uuid, 'ncd_reminder', {message: message_text.html_safe, notifiables: all.pluck(:uuid)})
    end

    def send_browser_push_notifications(company)
      send_push_notification_on_mobile(company)
      send_push_notification_on_web(company)
    end

    def send_push_notification_on_mobile(company)
      if company.can_send_push_notification?
      notification = PushNotificationServiceMobile.new(company, {message: "Reminder To Call Leads. Next Call In 30 Mins.", notifiables: all.pluck(:uuid)})
      response, is_sent  = notification.deliver
      notification_log = company.push_notification_logs.build(
        device_type: 'mobile'
      )
      if is_sent
        notification_log.push_notification_id = response['id']
        notification_log.response = 'success'
        notification_log.sent_at = response['send_at']
        notification_log.save
      else
        notification_log.response = response.to_s
        notification_log.save
      end
      end
    end

    def send_push_notification_on_web(company)
      if company.can_send_push_notification?
        notification = PushNotificationServiceWeb.new(company, {message: "Reminder To Call Leads. Next Call In 30 Mins.", notifiables: all.pluck(:uuid)})
        response, is_sent  = notification.deliver
        notification_log = company.push_notification_logs.build(
          device_type: 'web_app'
        )
        if is_sent
          notification_log.push_notification_id = response['id']
          notification_log.response = 'success'
          notification_log.sent_at = response['send_at']
          notification_log.save
        else
          notification_log.response = response.to_s
          notification_log.save
        end
      end
    end


  end

  def may_add_user?
    self.is_sysad? || self.company.can_add_users
  end


  def all_managers_list
    return get_manager_line self.managers
  end

  def sid_active?
    self.exotel_sid&.is_active? || self.mcube_sid&.is_active? || self.agent_id.present? || self.company.way_to_voice_enabled
  end

  def get_manager_line users
    final_manager_array = [users].flatten
    while true
      this_manager_line = get_managers_of users
      users = this_manager_line
      if users.blank?
        break
      else
        final_manager_array << users
      end
    end
    return final_manager_array.flatten.compact.uniq
  end

  def get_managers_of users_array
    to_send_data = []
    users_array.each do |user|
      to_send_data << user.managers.uniq
    end
    return to_send_data.compact.flatten.uniq
  end

  def notify_incoming_call(calling_no)
    company = self.company
    client = company.leads.find_by(mobile: calling_no.last(10))
    if client.present?
      message_text = "Incoming Call From #{client.name} (#{calling_no}) : #{client.project&.name}"
    else
      message_text = "Incoming Call From Unknown (#{calling_no})"
    end
    Pusher.trigger(self.company.uuid, 'incoming_call', {message: message_text, notifiables: [self.uuid]})
  end

end

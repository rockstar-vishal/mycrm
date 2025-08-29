class Leads::CallLog < ActiveRecord::Base

  enum third_party_id:{
    "exotel": 1,
    "mcube": 2,
    "callerdesk": 3,
    "czentrixcloud": 4,
    "way2voice": 5
  }

  ANSWERED_STATUS= ['ANSWER', 'answered']
  MISSED_STATUS=['no-answer', 'Missed', 'NOANSWER', 'busy', 'noans', 'client-hangup','canceled']
  ABANDONED_STATUS= ['CANCEL', 'failed', 'Executive Busy']
  COMPLETED_STATUS=['completed', 'ANSWER', 'Call Complete', 'answered']

	belongs_to :lead, class_name: "::Lead"
  belongs_to :user, class_name: '::User'

  has_many :call_attempts, through: :lead

  validates :start_time,  presence: true

  after_commit :send_push_notification,:web_push_notification

  after_commit :log_call_attempt, on: :create

  other_data_field = [
    :status,
    :direction,
    :phone_number_sid,
    :executive_call_duration,
    :executive_call_status,
    :lead_call_duration,
    :lead_call_status,
    :caller,
    :call_type,
    :session_id
  ]

  scope :incoming, -> {where("leads_call_logs.other_data->>'direction'= ?", 'incoming')}
  scope :not_incoming, -> {where.not("leads_call_logs.other_data->>'direction'= ?", 'incoming')}

  scope :todays_calls, -> {where("leads_call_logs.created_at BETWEEN ? AND ?",Date.today.beginning_of_day, Date.today.end_of_day)}
  scope :past_calls, -> {where("leads_call_logs.created_at < ?", Date.today.beginning_of_day)}
  scope :missed, -> {where("leads_call_logs.other_data->>'status' IN (?)", Leads::CallLog::MISSED_STATUS)}
  scope :answered, -> {where("leads_call_logs.other_data->>'status' IN (?)", Leads::CallLog::ANSWERED_STATUS)}
  scope :completed_calls, -> {where("leads_call_logs.other_data->>'status' IN (?)", Leads::CallLog::COMPLETED_STATUS)}
  scope :abandoned_calls, -> {where("leads_call_logs.other_data->>'status' IN (?)", Leads::CallLog::ABANDONED_STATUS)}
  scope :yesterday_calls, -> {where("leads_call_logs.created_at BETWEEN ? AND ?", Date.yesterday.beginning_of_day, Date.today.beginning_of_day)}

  def display_to_number(user)
    return "XXXXXXXXXX" if user.is_telecaller?
    return self.to_number
  end

  def display_from_number(user)
    return "XXXXXXXXXX" if user.is_telecaller?
    return self.from_number
  end


  def default_fields_values
    self.other_data || {}
  end

  other_data_field.each do |method|
    define_method("#{method}=") do |val|
      self.other_data_will_change!
      self.other_data = (self.other_data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end

  def send_push_notification
    if Leads::CallLog::MISSED_STATUS.include? self.status
      company = self.lead.company
      client = self.lead
      user = self.user
      if client.present?
        message_text = "Missed an Incoming Call From #{client.name} (#{self.from_number}) : #{client.project&.name}"
      else
        message_text = "Missed an Incoming call from Unknown (#{self.from_number})"
      end
      Pusher.trigger(self.lead.company.uuid, 'missed_call', {message: message_text, notifiables: [user.uuid]})
    end
  end

  def web_push_notification
    if self.user.present? && self.user.company.can_send_push_notification? && Leads::CallLog::MISSED_STATUS.include?(self.status)
      company = self.lead.company
      client = self.lead
      user = self.user
      if client.present?
        message_text = "Missed an Incoming Call From #{client.name} (#{self.from_number}) : #{client.project&.name}"
      else
        message_text = "Missed an Incoming call from Unknown (#{self.from_number})"
      end
      mobile_notification = PushNotificationServiceMobile.new(company, {message: message_text, notifiables: [user.uuid], target_url: "https://#{lead.company.mobile_domain}/Lead/#{lead.uuid}"})
      web_notification = PushNotificationServiceWeb.new(company, {message: message_text, notifiables: [user.uuid]})
      mobile_notification.deliver
      web_notification.deliver
    end
  end

  def log_call_attempt
    if self.user.company.call_response_report.present? && self.direction != 'incoming' && self.lead.call_attempts.where("user_id = (?) AND response_time iS NOT NULL", self.user_id).blank?
      lead_assigned_at = self.lead.audits.select{|audit| audit.audited_changes["user_id"].present? && (audit.audited_changes["user_id"].is_a?(Array) ? audit.audited_changes["user_id"][0]== self.user_id : audit.audited_changes["user_id"][0]== self.user_id)}.sort_by(&:created_at).first.created_at rescue self.lead.created_at
      response_time = (self.created_at.in_time_zone - lead_assigned_at.in_time_zone).to_i rescue nil
      self.lead.call_attempts.create(
        user_id: self.lead.user_id,
        response_time: response_time
      )
    end
  end

  class << self

    def advance_search(search_params)
      call_logs = all
      if search_params[:display_from].present?
        display_from = Time.zone.parse(search_params[:display_from])
      end
      if search_params[:past_calls_only].present?
        call_logs = call_logs.past_calls
      end
      if search_params[:todays_calls].present?
        call_logs = call_logs.todays_calls
      end
      if search_params[:missed_calls].present?
        call_logs = call_logs.missed
      end
      if search_params[:completed].present?
        call_logs = call_logs.completed_calls
      end
      if search_params[:abandoned_calls].present?
        call_logs = call_logs.abandoned_calls
      end
      if search_params[:direction].present?
        call_logs = (search_params[:direction] == 'incoming') ? call_logs.incoming : call_logs.not_incoming
      end
      if search_params[:call_direction].present?
        call_logs = search_params["call_direction"] == "Incoming" ? call_logs.incoming : call_logs.not_incoming
      end
      if search_params[:start_date].present?
        created_at_from = Time.zone.parse(search_params["start_date"]).at_beginning_of_day
        call_logs = call_logs.where("leads_call_logs.created_at >= ?", created_at_from)
      end
      if search_params[:end_date].present?
        created_at_upto = Time.zone.parse(search_params["end_date"]).at_end_of_day
        call_logs = call_logs.where("leads_call_logs.created_at <= ?", created_at_upto)
      end
      if search_params[:created_at_from].present?
        created_at_from = Time.zone.parse(search_params["created_at_from"]).at_beginning_of_day
        call_logs = call_logs.where("leads_call_logs.created_at >= ?", created_at_from)
      end
      if search_params[:created_at_upto].present?
        created_at_upto = Time.zone.parse(search_params["created_at_upto"]).at_end_of_day
        call_logs = call_logs.where("leads_call_logs.created_at <= ?", created_at_upto)
      end
      if search_params[:lead_ids].present?
        call_logs = call_logs.where(lead_id: search_params[:lead_ids])
      end
      if display_from.present?
        call_logs = call_logs.where("leads_call_logs.created_at > ?", display_from)
      end
      if search_params[:user_ids].present?
        call_logs = call_logs.where("leads_call_logs.user_id IN (?)", search_params[:user_ids])
      end
      if search_params[:project_ids].present?
        call_logs = call_logs.joins{lead}.where(lead: {project_id: search_params[:project_ids]})
      end
      if search_params[:first_call_attempt].present?
        call_logs_ids = call_logs.joins{call_attempts}.where.not(call_attempts: {response_time: nil}).ids.uniq
        call_logs = call_logs.where(id: call_logs_ids).select("DISTINCT ON (leads_call_logs.lead_id) leads_call_logs.*")
      end
      call_logs
    end

  end

end

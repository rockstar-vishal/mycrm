class PushNotificationServiceWeb

  attr_accessor :company, :user_ids, :notification

  def initialize(company, notification_hash)
    @company = company
    @user_ids = notification_hash[:notifiables]
    message = notification_hash[:message]
    action_target_url = notification_hash[:target_url].present? ? notification_hash[:target_url] :  "http://#{company.mobile_domain}"
    set_push_pad_creds
    @notification = Pushpad::Notification.new({
      body: message,
      title: "CRM Notification",
      icon_url: company.logo.url,
      target_url: "https://#{company.domain}",
      actions: [
        {
          title: "Lead Detail",
          target_url: action_target_url
        }
      ],
      send_at: Time.current
    })
    notification
  end

  def deliver
    begin
      user_ids = @user_ids
      [(notification.deliver_to user_ids, tags: ['web_app']), true]
    rescue => e
      [e, false]
    end
  end

  def set_push_pad_creds
    Pushpad.auth_token = company.push_notification_setting.token
    Pushpad.project_id = company.push_notification_setting.project_key
  end

end
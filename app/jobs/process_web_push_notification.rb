class ProcessWebPushNotification

  @queue = :web_push_notification
  @process_wpn_logger = Logger.new('log/web_push_notification.log')


  def self.perform id
    errors=[]
    begin
      lead = Lead.find(id)
      company = lead.company
      message_text = "Lead #{lead.name}, assigned to #{lead.user&.name} has been created at #{lead.created_at.strftime('%d-%b-%y %H:%M %p')}"
      web_notification = PushNotificationServiceWeb.new(company, {message: message_text, notifiables: [lead.user.uuid], target_url: "https://#{lead.company.domain}/Lead/#{lead.uuid}"})
      web_notification.deliver
    rescue Exception => e
      error_message = "#{e.backtrace[0]} --> #{e}"
      errors << {message: error_message}
    end
    @process_wpn_logger.info("result for Lead ID- #{id} - #{errors}")
  end

end
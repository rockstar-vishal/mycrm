class ProessAssignmentChangeNotification
  @queue = :process_assignment_change_notification
  @status_update_logger = Logger.new('log/assignment_change_notification.log')

  def self.perform(id)
    @status_update_logger.info("stared at #{Time.zone.now}")
    lead = Lead.find_by(id: id)
    company = lead.company
    errors = []
    begin
      if company.mailchimp_integration.active?
        response =  send_mail_chimp_email(lead)
        @status_update_logger.info("Mail Sent - #{response}")
      else
        @status_update_logger.info("integration not active - #{errors}")
      end
    rescue Exception => e
      error_message = "#{e.backtrace[0]} --> #{e}"
      errors << {message: error_message}
    end
    @status_update_logger.info("result for #{Time.zone.now} - #{errors}")
  end

  def self.send_mail_chimp_email(lead)
    body = html_body(lead)
    company = lead.company
    url = 'https://mandrillapp.com/api/1.0/messages/send.json'
    request_body = {
      "key": company.mailchimp_integration.token,
      "message": {"html": "#{body}",
      "from_email": "#{company.default_from_email}",
      "to": [{"email": "#{lead.user.email}", "type": "to"}],
      "subject": "New Lead Assigned",
      "important": true,
      "track_opens": false,
      "track_clicks": false,
      "auto_text": false,
      "auto_html": false,
      "url_strip_qs": false,
      "preserve_recipients": false,
      "view_content_link": false,
      "bcc_address": "",
      "tracking_domain": "",
      "signing_domain": "",
      "return_path_domain": "",
      "merge": false,
      "merge_language": "mailchimp",
      "global_merge_vars": [],
      "merge_vars":[],
      "tags":[],
      "subaccount": company.mailchimp_integration.integration_key,
      "google_analytics_domains": [],
      "recipient_metadata": [],
      "attachments": [],
      "images":[]}, "async": false
    }.to_json
    ExotelSao.secure_post(url, request_body)
  end

  def self.html_body(lead)
     mail_body = ApplicationController.new.render_to_string(
      :template => 'user_mailer/assignment_notification.html.haml',
      :layout => nil,
      :locals => { :@lead => lead}
    )
    mail_body = mail_body.html_safe
  end

end
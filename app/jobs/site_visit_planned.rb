class SiteVisitPlanned
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :site_visit_planned
  @site_visit_planned_logger = Logger.new('log/site_visit_planned.log')

  def self.perform
    begin
      Company.joins{setting}.where("companies_settings.setting_data ->> 'mobicomm_sms_service_enabled' = ?", 'true').each do |company|
        if Time.current >= Time.zone.parse('5:30 PM')
          leads = company.leads.where(tentative_visit_planned: (Date.today + 1.day).beginning_of_day..(Date.today + 1.day).end_of_day)
        else
          leads = company.leads.where(tentative_visit_planned: Date.today.beginning_of_day..Date.today.end_of_day)
        end
        leads.each do |lead|
          message_text = "Dear #{lead.name}, Your site visit at #{lead.project_name} is scheduled at #{lead.tentative_visit_planned.strftime("%d %B %Y %I:%M%p")}. Do call and let me know if you want to change the schedule. \nRegards, \n#{lead.user&.name} \n#{@lead&.user&.mobile} \nTeam #{lead.project_name}"
          url_encoded_sms_text = URI.encode_www_form_component(message_text)
          uri = URI.parse("http://mobicomm.dove-sms.com//submitsms.jsp?user=Golden5&key=1f6a246169XX&mobile=+917798223422&message=#{url_encoded_sms_text}&senderid=GOLDNA&accusage=1&entityid=1234567891112131415&tempid=1034567891112131819")
          response = Net::HTTP.get(uri)
          @site_visit_planned_logger.info("Done For Lead #{lead.id} - #{Time.current}")
        end
        @site_visit_planned_logger.info("Done For Company #{company.id} - #{Time.current}")
      end
    rescue => e
      @site_visit_planned_logger.info("Failed For Company #{company.id} - #{Time.current}")
    end
  end

end

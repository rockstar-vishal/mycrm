class LeadRegistration
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :lead_registration
  @lead_registration_logger = Logger.new('log/lead_registration.log')

  def self.perform id
    sms = ::SystemSms.find(id)
    begin
      @lead_registration_logger.info("processing sms-#{id}")
      url_encoded_sms_text = URI.encode_www_form_component(sms.text)
      uri = URI.parse("http://mobicomm.dove-sms.com//submitsms.jsp?user=Golden5&key=1f6a246169XX&mobile=#{sms.mobile}&message=#{url_encoded_sms_text}&senderid=GldnAb&accusage=1&entityid=1234567891112131415&tempid=1707165286980755569")

      response = Net::HTTP.get(uri)

      @lead_registration_logger.info("processing sms-#{id} - 2")

      sent = true
      message = response
      @lead_registration_logger.info("processing sms-#{id} - 3")
    rescue Exception => e
      sent = false
      message = e.to_s
      @lead_registration_logger.info("processing sms-#{id} - 4")
    end
    sms.update_attributes(:response=>message, :sent=>sent)
    @lead_registration_logger.info("processing sms-#{id} - 6")
    return true
  end
end

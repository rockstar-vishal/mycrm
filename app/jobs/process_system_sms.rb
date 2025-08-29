class ProcessSystemSms
  require 'uri'
  require 'net/http'
  require 'json'

  @queue = :process_system_sms
  @process_system_sms_logger = Logger.new('log/process_system_sms.log')

  def self.perform id
    sms = ::SystemSms.find(id)
    auth_key = sms.company.sms_integration.integration_key
    url = sms.company.sms_integration.url
    begin
      if url.present?
        @process_system_sms_logger.info("processing sms-#{id}")
        response = ExotelSao.secure_post("#{url}?From=02248900233&To=#{sms.mobile}&Body=#{sms.text}", {})
        sent = true
        message= response["SMSMessage"]["Sid"] rescue nil
      else
        @process_system_sms_logger.info("processing sms-#{id}")
        url_encoded_sms_text = URI.encode_www_form_component(sms.text)
        uri=URI.parse("#{url}?authkey=#{auth_key}&mobiles=#{sms.mobile.strip}&message=#{url_encoded_sms_text}&sender=HAWARE&DLT_TE_ID=#{sms.template_id}")
        response = Net::HTTP.get(uri)

        @process_system_sms_logger.info("processing sms-#{id} - 2")

        sent = true
        message = response
        @process_system_sms_logger.info("processing sms-#{id} - 3")
      end
    rescue Exception => e
      sent = false
      message = e.to_s
      @process_system_sms_logger.info("processing sms-#{id} - 4")
    end
    sms.update_attributes(:response=>message, :sent=>sent)
    @process_system_sms_logger.info("processing sms-#{id} - 6")
    return true
  end
end

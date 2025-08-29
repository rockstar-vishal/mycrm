class SmsService

  class << self

    def send_otp(otp)
      begin
        text = "Your One Time Otp Is #{otp.code}"
        url = otp.company.sms_integration.url
        response = ExotelSao.secure_post("#{url}?From=02071178100&To=#{otp.validatable_data}&Body=#{text}", {})
        sent = true
        message= response["SMSMessage"]["Sid"] rescue nil
        return true, response
      rescue Exception => e
        return false, e.to_s
      end
    end

  end

end
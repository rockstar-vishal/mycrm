module OtpGenerator

  extend ActiveSupport::Concern

  included do

    has_many :otps, class_name: 'Otp'

    def generate_sms_otp(data)
      if self.otps.for_phones.send("#{data[:event_type]}").unused.gen_in_last_20_minutes.where(validatable_data: data[:validatable_data]).present?
        otp = self.otps.for_phones.unused.gen_in_last_20_minutes.last
        otp.send_sms_alert
        return true, otp
      else
        otp = self.otps.for_phones.build(validatable_data: data[:validatable_data], event_type: data[:event_type])
        if otp.save
          return true, otp
        else
          return false, otp.errors.full_messages.join(', ')
        end
      end
    end

    def validate_otp(data)
      otp = self.otps.send("#{data[:event_type]}").unused.gen_in_last_20_minutes.find_by(code: data[:otp], validatable_data: data[:validatable_data])
      if otp.present?
        otp.use
      end
    end

  end
end
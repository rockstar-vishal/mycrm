class IncomingCall < ActiveRecord::Base

  def default_fields_values
    self.other_data || {}
  end

  other_data_field = [
    :status,
    :direction,
    :executive_call_duration,
    :executive_call_status,
    :lead_call_duration,
    :lead_call_status,
    :caller,
    :call_type,
    :sid
  ]

  other_data_field.each do |method|
    define_method("#{method}=") do |val|
      self.other_data_will_change!
      self.other_data = (self.other_data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end
end

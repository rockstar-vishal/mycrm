class Companies::Integration < ActiveRecord::Base
  belongs_to :company
  validates :key, presence: true

  scope :for_housing, -> {where(:key=>"housing")}
  scope :for_exotel, -> {where(key: 'exotel')}
  scope :for_mailchimp, -> {where(key: 'mailchimp')}
  scope :for_mcube, -> {where(key: 'mcube')}
  scope :sms, -> {where(key: 'sms')}
  scope :for_common_floor, -> {where(key: 'common_floor')}

  INTEGRATION_FIELDS = [
    :integration_key,
    :token,
    :sid,
    :callback_url,
    :url
  ]

  def default_fields_values
    self.data || {}
  end

  INTEGRATION_FIELDS.each do |method|
    define_method("#{method}=") do |val|
      if ["true", "false", "t", "f"].include?(val)
        val = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(val)
      end
      self.data_will_change!
      self.data = (self.data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end

end

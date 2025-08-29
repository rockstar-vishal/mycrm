class PushNotificationSetting < ActiveRecord::Base

  belongs_to :company, inverse_of: :push_notification_setting

end

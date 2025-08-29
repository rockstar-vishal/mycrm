class PushNotificationLog < ActiveRecord::Base
  enum device_type:{
    "mobile": 1,
    "web_app": 2
  }
end

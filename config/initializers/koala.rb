Koala.configure do |config|
  config.app_id = CRMConfig.fb_app_id
  config.app_secret = CRMConfig.fb_app_secret
  api_version = "v10.0"
  # See Koala::Configuration for more options, including details on how to send requests through
  # your own proxy servers.
end
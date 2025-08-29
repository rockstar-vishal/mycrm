require 'raven'
require 'resque/failure/multiple'
require 'resque/failure/redis'
require 'resque-sentry'

if Rails.env.production?
  Resque::Failure::Sentry.logger = "resque"

  Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Sentry]
  Resque::Failure.backend = Resque::Failure::Multiple
  Raven.configure do |config|
    config.dsn = CRMConfig.SENTRY_DSN
  end
end

require 'resque/server'

Resque::Server.use(Rack::Auth::Basic) do |user, password|
  password == CRMConfig.resque_password
end
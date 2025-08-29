require 'resque/scheduler'
require 'resque/scheduler/server'
Dir["#{Rails.root}/app/jobs/*.rb"].each { |file| require file }
Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")
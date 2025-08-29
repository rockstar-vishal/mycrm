require 'redis-namespace'
redis_connection = Redis.new(:host => CRMConfig.redis_host, :port => CRMConfig.redis_port, :thread_safe => true)
Redis.current = Redis::Namespace.new(:h4a_crm, :redis => redis_connection)

Resque.redis = Redis.current
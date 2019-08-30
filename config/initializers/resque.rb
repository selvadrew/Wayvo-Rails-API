# Resque.redis = ENV['REDIS_URL'] + '/0' if ENV['REDIS_URL'].present?
Resque.redis = ENV['REDIS_URL'] if ENV['REDIS_URL'].present?

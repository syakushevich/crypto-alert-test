# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/0' } }

  # Sidekiq-scheduler configuration
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.expand_path('../sidekiq_schedule.yml', __dir__), fallback: false) || {}
    Sidekiq::Scheduler.reload_schedule!
  end

  config.logger.level = Logger::WARN
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/0' } }
end

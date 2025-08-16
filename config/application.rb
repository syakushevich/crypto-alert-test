require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module CryptoAlerter
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w(assets tasks))
    config.api_only = true

    config.active_job.queue_adapter = :sidekiq
    config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' } }
  end
end

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LibraOc
  class Application < Rails::Application

    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end

    config.tinymce.install = :copy

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.eager_load_paths << "#{Rails.root}/lib"

    #config.active_job.queue_adapter = :inline
    config.active_job.queue_adapter = :sidekiq

    # specify the name of the IP whitelist file
    config.ip_whitelist = "#{Rails.root}/data/ipwhitelist.txt"

    Rails.application.routes.default_url_options[:host] = ENV['BASE_URL']
    config.action_controller.asset_host = ENV['BASE_URL']

  end
end

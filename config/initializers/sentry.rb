Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.dsn = 'http://2925ab490f984f4e8113ef1803b7ce6b:4edf9b330a4a4378bdf4206e8866f55a@sentry.lib.virginia.edu:9000/3'
  config.environments = ['staging', 'production']
end

Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load

  config.assets.debug = false
  config.assets.digest = true
  config.assets.raise_runtime_errors = true

  config.logger = Logger.new(STDOUT)

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               'gmail.com',
    user_name:            'bobar.tdb@gmail.com',
    password:             ENV['GMAIL_PASSWORD'],
    authentication:       'plain',
    enable_starttls_auto: true,
  }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
end
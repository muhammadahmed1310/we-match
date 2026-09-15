# frozen_string_literal: true

# Shared SMTP settings. Loaded from environment files, so this stays a plain
# Ruby file rather than an autoloaded constant.
module WeMatchSmtp
  def self.configured?
    ENV["SMTP_ADDRESS"].present? && ENV["SMTP_USERNAME"].present? && ENV["SMTP_PASSWORD"].present?
  end

  def self.settings
    {
      address: ENV.fetch("SMTP_ADDRESS"),
      port: ENV.fetch("SMTP_PORT", "587").to_i,
      domain: ENV.fetch("SMTP_DOMAIN", "womenemerging.org"),
      user_name: ENV.fetch("SMTP_USERNAME"),
      password: ENV.fetch("SMTP_PASSWORD"),
      authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
      enable_starttls_auto: true,
      open_timeout: 10,
      read_timeout: 10
    }
  end
end

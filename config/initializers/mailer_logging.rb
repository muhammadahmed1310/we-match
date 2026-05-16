# frozen_string_literal: true

if Rails.env.development?
  ActionMailer::Base.register_interceptor(
    Class.new do
      def self.delivering_email(message)
        Rails.logger.info(
          "[WE Match Mail] To: #{message.to.join(', ')} | Subject: #{message.subject}"
        )
      end
    end
  )
end

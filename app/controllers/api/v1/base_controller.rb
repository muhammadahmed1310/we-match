# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      # The API authenticates with a shared token instead of an admin session.
      allow_participant_access
      before_action :require_api_token

      private

      def require_api_token
        return if valid_api_token?

        render_json_error("Invalid or missing API token.", status: :unauthorized)
      end

      def valid_api_token?
        expected = self.class.configured_api_token
        return false if expected.blank?

        presented = presented_api_token
        return false if presented.blank?

        ActiveSupport::SecurityUtils.secure_compare(presented, expected)
      end

      def presented_api_token
        from_header = request.headers["Authorization"].to_s[/\ABearer\s+(.+)\z/, 1]
        from_header.presence || request.headers["X-Api-Token"].presence
      end

      def self.configured_api_token
        ENV["WE_MATCH_API_TOKEN"].presence ||
          Rails.application.credentials.dig(:api_token).presence
      end
    end
  end
end

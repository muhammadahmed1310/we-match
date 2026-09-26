class ApplicationController < ActionController::Base
  include AdminAuthentication
  include Paginates

  allow_browser versions: :modern

  private

  def render_json_error(message, status: :unprocessable_entity)
    render json: { error: message }, status: status
  end
end

# frozen_string_literal: true

class BaseController < ApplicationController
  wrap_parameters false

  private

  def require_current_user!
    render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
  end

  def current_user
    @current_user ||= user_from_bearer_token
  end

  def user_from_bearer_token
    header = request.headers["Authorization"].to_s
    scheme, token = header.split(" ", 2)
    return nil unless scheme&.casecmp?("Bearer")
    return nil if token.blank?

    payload = JsonWebToken.decode(token.strip)
    return nil unless payload

    user_id = payload[:user_id] || payload["user_id"]
    return nil if user_id.blank?

    User.find_by(id: user_id)
  end
end

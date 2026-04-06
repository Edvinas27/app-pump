# frozen_string_literal: true

class BaseController < ApplicationController
  wrap_parameters false

  private

  def current_user
    return @current_user if defined?(@current_user)

    payload = JsonWebToken.decode(bearer_token)
    @current_user = payload ? User.find_by(id: payload[:user_id]) : nil
  end

  def require_current_user!
    return if current_user

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def bearer_token
    auth_header = request.headers["Authorization"].to_s
    parts = auth_header.split
    return nil unless parts.length == 2 && parts.first == "Bearer"

    parts.last
  end
end

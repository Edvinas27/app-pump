class ApplicationController < ActionController::API
  def current_user
    return @current_user if instance_variable_defined?(:@current_user)

    token = request.headers["Authorization"].to_s.sub(/\ABearer\s+/i, "")
    return @current_user = nil if token.blank?

    payload = JsonWebToken.decode(token)
    return @current_user = nil if payload.blank?

    @current_user = User.find_by(id: payload[:user_id])
  end

  def require_current_user!
    return if current_user

    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end

# frozen_string_literal: true

class SessionsController < BaseController
  def create
    result = Users::Login.for(session_params[:email], session_params[:password])

    if result[:success]
      render json: {
        user: user_json(result[:user]),
        token: JsonWebToken.encode(user_id: result[:user].id)
      }, status: :ok
    else
      render json: { error: result[:error] }, status: :unauthorized
    end
  end

  private

  def session_params
    params.permit(:email, :password)
  end

  def user_json(user)
    user.as_json(only: %i[id email username created_at])
  end
end

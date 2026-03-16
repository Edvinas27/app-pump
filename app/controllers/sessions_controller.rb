# frozen_string_literal: true

class SessionsController < BaseController
  def create
    result = Users::Login.for(email: session_params[:email], password: session_params[:password])

    if result[:success]
      render json: { user: user_json(result[:user]) }, status: :ok
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

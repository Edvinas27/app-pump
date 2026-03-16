# frozen_string_literal: true

class RegistrationsController < BaseController
  def create
    result = Users::Register.for(registration_params)

    if result[:success]
      render json: user_json(result[:user]), status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.permit(:email, :username, :password).to_h
  end

  def user_json(user)
    user.as_json(only: %i[id email username created_at])
  end
end

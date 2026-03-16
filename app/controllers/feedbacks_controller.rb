# frozen_string_literal: true

class FeedbacksController < BaseController
  def get
    result = Feedbacks::Get.for({})

    render json: result, status: :ok
  end

  def create
    result = Feedbacks::Create.for(feedback_params)

    if result[:success]
      render json: result[:feedback], status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def feedback_params
    params.permit(:comment, :rating).to_h
  end
end


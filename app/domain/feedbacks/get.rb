# frozen_string_literal: true

class Feedbacks::Get
  include Interactor::Initializer

  initialize_with :params

  def run
    Feedback.all.order(created_at: :desc)
  end
end


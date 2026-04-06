# frozen_string_literal: true

class Feedbacks::Create
  include Interactor::Initializer

  initialize_with :params

  def run
    result = Feedback.create(params)

    if result.persisted?
      { success: true, feedback: result }
    else
      { success: false, errors: ::TranslateErrors.for(result) }
    end
  end
end


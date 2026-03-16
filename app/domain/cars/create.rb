# frozen_string_literal: true

class Cars::Create
  include Interactor::Initializer

  initialize_with :params

  def run
    result = Car.create(params)

    if result.persisted?
      { success: true, car: result }
    else
      { success: false, errors: ::TranslateErrors.for(result) }
    end
  end
end

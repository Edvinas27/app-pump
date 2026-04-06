# frozen_string_literal: true

class Users::Register
  include Interactor::Initializer

  initialize_with :params

  def run
    result = User.create(params)

    if result.persisted?
      { success: true, user: result }
    else
      { success: false, errors: ::TranslateErrors.for(result) }
    end
  end
end

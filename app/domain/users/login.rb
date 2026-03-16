# frozen_string_literal: true

class Users::Login
  include Interactor::Initializer

  initialize_with :email, :password

  def run
    user = User.find_by(email: email)

    if user&.authenticate(password)
      { success: true, user: user }
    else
      { success: false, error: "Invalid email or password" }
    end
  end
end

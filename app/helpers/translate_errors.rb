# frozen_string_literal: true

class TranslateErrors
  include Interactor::Initializer

  initialize_with :instance

  def run
    translate_errors(instance)
  end

  private

  def translate_errors(instance)
    return {} if instance.errors.empty?

    instance.errors.messages.transform_values(&:first)
  end
end

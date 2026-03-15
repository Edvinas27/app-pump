# frozen_string_literal: true

module SpecHelper
  def json_response
    JSON.parse(response.body)
  end

  RSpec.configure do |config|
    config.include SpecHelper
  end
end

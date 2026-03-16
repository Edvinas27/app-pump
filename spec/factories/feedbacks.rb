# frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    comment { "Great app!" }
    rating { 5 }
  end
end


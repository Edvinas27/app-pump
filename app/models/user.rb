# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :user_cars, dependent: :destroy
  has_many :cars, through: :user_cars

  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true
  validates :username, length: { in: 3..40 }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :password, format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}\z/,
    message: "turi būti 8+ simbolių, didžioji, mažoji raidė ir skaičius"
  }, if: -> { password.present? }
end

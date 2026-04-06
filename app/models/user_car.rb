# frozen_string_literal: true

class UserCar < MainModel
  belongs_to :user
  belongs_to :car

  validates :car_id, uniqueness: { scope: :user_id }
end

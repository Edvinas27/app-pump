# frozen_string_literal: true

class FuelType < MainModel
  has_many :cars

  validates :name, presence: true, uniqueness: true
end

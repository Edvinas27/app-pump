class CreateUserCars < ActiveRecord::Migration[8.0]
  def change
    create_table :user_cars do |t|
      t.references :user, null: false, foreign_key: true
      t.references :car, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_cars, [:user_id, :car_id], unique: true
  end
end

class AddYearToCars < ActiveRecord::Migration[8.0]
  def change
    add_column :cars, :year, :integer
    change_column_null :cars, :year, false, 2000

    remove_index :cars, name: "idx_cars_unique_combination"
    add_index :cars,
              [:brand_name, :model, :fuel_type_id, :co2_emission, :year],
              unique: true,
              name: "idx_cars_unique_combination"
  end
end

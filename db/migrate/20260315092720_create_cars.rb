class CreateCars < ActiveRecord::Migration[8.0]
  def change
    create_table :cars do |t|
      t.string :brand_name, null: false
      t.string :model, null: false
      t.float :co2_emission, null: false
      t.references :fuel_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :cars,
              [:brand_name, :model, :fuel_type_id, :co2_emission],
              unique: true,
              name: 'idx_cars_unique_combination'
  end
end
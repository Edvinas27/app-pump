class CreateFuelTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :fuel_types do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :fuel_types, :name, unique: true
  end
end

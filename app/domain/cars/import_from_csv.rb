require 'csv'

#Cars::ImportFromCsv.call("db/data/officialcars.csv")
class Cars::ImportFromCsv
  def self.call(file_path)
    CSV.foreach(file_path, headers: true) do |row|
      Cars::Create.for(
        brand_name: row["Brand"],
        model: row["Model"],
        co2_emission: row["Ewltp (g/km)"].to_f,
        fuel_type_id: find_fuel_type(row["Fuel"])
      )
    end
  end

  def self.find_fuel_type(name)
    FuelType.find_or_create_by(name: name)&.id
  end
end
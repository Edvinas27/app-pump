require 'json'

#Cars::ExportToJson.call
class Cars::ExportToJson
  def self.call(output_path = "db/data/officialcars.json")
    cars = Car.includes(:fuel_type).all

    data = cars.map do |car|
      {
        id: car.id,
        brand_name: car.brand_name,
        model: car.model,
        year: car.year,
        co2_emission: car.co2_emission,
        fuel_type: car.fuel_type&.name
      }
    end

    dir = File.dirname(output_path)
    Dir.mkdir(dir) unless Dir.exist?(dir)

    File.write(output_path, JSON.pretty_generate(data))

    puts "Exported #{data.size} cars to #{output_path}"
    data
  end
end
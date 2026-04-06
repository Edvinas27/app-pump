require 'rails_helper'

RSpec.describe Cars::ImportFromCsv do
  let(:csv_path) { Rails.root.join("spec/fixtures/files/testcars.csv") }

  before do
    File.write(csv_path, <<~CSV)
      Brand,Model,Ewltp (g/km),Fuel
      BMW,X5,120,Diesel
      Toyota,Corolla,90,Petrol
    CSV
  end

  after do
    File.delete(csv_path) if File.exist?(csv_path)
    Car.delete_all
    FuelType.delete_all
  end

  it "imports cars from CSV" do
    expect {
      Cars::ImportFromCsv.call(csv_path)
    }.to change(Car, :count).by(2)

    expect(Car.first.brand_name).to eq("BMW")
    expect(Car.first.model).to eq("X5")
    expect(Car.first.co2_emission).to eq(120.0)
    expect(Car.last.brand_name).to eq("Toyota")
    expect(Car.last.model).to eq("Corolla")
    expect(Car.last.co2_emission).to eq(90.0)

    expect(FuelType.count).to eq(2)

    expect(FuelType.first.id).to eq(Car.first.fuel_type_id)
    expect(FuelType.last.id).to eq(Car.last.fuel_type_id)
  end

    it "converts co2_emission to float" do
    Cars::ImportFromCsv.call(csv_path)

    expect(Car.first.co2_emission).to be_a(Float)
  end

  it "normalizes fuel type values" do
    File.write(csv_path, <<~CSV)
      Brand,Model,Ewltp (g/km),Fuel
      BMW,X5,120, Diesel
      Audi,A4,110,DIESEL
    CSV

    Cars::ImportFromCsv.call(csv_path)

    expect(FuelType.count).to eq(1)
    expect(FuelType.first.name).to eq("diesel")
  end

  it "does not create duplicate fuel types on repeated import" do
    Cars::ImportFromCsv.call(csv_path)
    Cars::ImportFromCsv.call(csv_path)

    expect(FuelType.count).to eq(2)
  end
end

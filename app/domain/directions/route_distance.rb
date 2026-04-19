# frozen_string_literal: true

module Directions
  # Mapbox returns route leg distance in meters; consumer UIs need km to two decimal places.
  module RouteDistance
    module_function

    def km_from_meters(meters)
      return nil if meters.nil?

      (meters.to_f / 1000).round(2)
    end

    def enrich_mapbox_payload(data)
      return data unless data.is_a?(Hash) && data["routes"].is_a?(Array)

      enriched = data["routes"].map do |route|
        next route unless route.is_a?(Hash)

        meters = route["distance"]
        route.merge("distance_km" => km_from_meters(meters))
      end

      data.merge("routes" => enriched)
    end
  end
end

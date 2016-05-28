class DirectionsController < ApplicationController

  def index
    origin = params[:origin]
    destination = params[:destination]

    @conn = Faraday.new(:url => 'https://maps.googleapis.com/maps/api/') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    response = @conn.get 'directions/json', { origin: origin, destination: destination, mode: "walking", key: $gmaps_key, alternatives: true }


    routes = JSON.parse(response.body)['routes']

    # TODO calculate streets_to_avoid
    streets_with_cars = get_busy_streets
    streets_to_avoid = streets_with_cars
    stats = get_stats

    routes_and_colisions_map = {}
    routes.each_with_index do |route,i|
      legs = route['legs'][0]
      distance_in_text = legs['distance']['text']
      duration_in_text = legs['duration']['text']
      steps = legs['steps']
      route_streets_coordinates = []
      route_streets_addresses   = []
      formatted_steps = []
      steps.each do |step|
        step_starting_point = "#{step['start_location']['lat']},#{step['start_location']['lng']}"
        step_ending_point   = "#{step['end_location']['lat']},#{step['end_location']['lng']}"
        step_starting_street = get_address(step_starting_point)
        step_ending_street = get_address(step_ending_point)

        unless route_streets_coordinates.include?(step_starting_point)
          route_streets_coordinates << step_starting_point
          route_streets_addresses   << step_starting_street
        end

        unless route_streets_coordinates.include?(step_ending_point)
          route_streets_coordinates << step_ending_point
          route_streets_addresses   << step_ending_street
        end
        if streets_to_avoid[:busy].include?(step_starting_street)
          starting_street_status = "busy"
        elsif streets_to_avoid[:normal].include?(step_starting_street)
          starting_street_status = "normal"
        else
          starting_street_status = "free"
        end

        if streets_to_avoid[:busy].include?(step_ending_street)
          ending_street_status = "busy"
        elsif streets_to_avoid[:normal].include?(step_ending_street)
          ending_street_status = "normal"
        else
          ending_street_status = "free"
        end

        final_step = {
          start_location: {lat: step['start_location']['lat'], lng: step['start_location']['lng'], name:step_starting_street, status: starting_street_status},
          end_location: {lat: step['end_location']['lat'], lng: step['end_location']['lng'], name: step_ending_street, status: ending_street_status}
        }

        formatted_steps << final_step
      end
      route_streets_addresses.uniq!

      routes_and_colisions_map[i] = {
        steps: formatted_steps,
        busy_streets: route_streets_addresses & streets_to_avoid[:busy],
        stats: stats
      }
    end

    render json: routes_and_colisions_map
  end

  private

  def get_address(coordinates)
    #https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&key=AIzaSyBUFZFchMpUpOq-j9X4piApksiJ5zg5zS0
    response = @conn.get 'geocode/json', { latlng: coordinates, key: 'AIzaSyBgqAZ4fLrPrQtDkNbGW91yK6bqCawq3qA' }
    streets = JSON.parse(response.body)

    most_relevant_street = ""
    streets['results'][0]['address_components'].each do |component|
      if component['types'].include?("route")
        most_relevant_street = component['long_name'].delete("^\u{0000}-\u{007F}")
        break
      end
    end
    most_relevant_street
  end

  def get_busy_streets
    busy_conn = Faraday.new(:url => 'http://fiware-porto.citibrain.com/v1/') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    response = busy_conn.get 'contextEntityTypes/RoadEvent', { key: $api_key, offset: 0, limit: 1000 }

    streets = JSON.parse(response.body)['contextResponses']

    street_states = {busy: [], normal: []}

    streets.each do |street|
      attributes = street['contextElement']['attributes']
      status = ""
      name  = ""
      attributes.each do |attribute|
        next unless ["status","street_name"].include?(attribute['name'])
        next unless attribute['value'].present?
        status = attribute['value'] if attribute['name'] == "status"
        name   = attribute['value'] if attribute['name'] == "street_name"
      end
      if status.present? and name.present?
        street_states[status.to_sym] << name
      end
    end
    street_states
  end

  def get_stats
    stats_conn = Faraday.new(:url => 'http://fiware-porto.citibrain.com/v1/') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    response = stats_conn.get 'contextEntityTypes/EnvironmentEvent', { key: $api_key, offset: 0, limit: 100 }

    elements = JSON.parse(response.body)['contextResponses']

    attribute_values = {}
    average_values = []

    elements.each do |element|
      element['contextElement']['attributes'].each do |attribute|
        next if attribute['name'] == "coordinates" or attribute['name'] == "timestamp"
        if attribute_values[attribute['name']]
          attribute_values[attribute['name']] << attribute['value']
        else
          attribute_values[attribute['name']] = [attribute['value']]
        end
      end
    end
    attribute_values.each_key do |element|
      next unless %w(carbon_monoxide humidity noise_level temperature solar_radiation).include?(element)
      value = (attribute_values[element].map(&:to_f).reduce(:+)/attribute_values[element].size).round(2).to_s
      case element
      when "noise_level"
        name = "Noise"
        value += " db"
      when "temperature"
        name = "Temperature"
        value += " Cº"
      when "solar_radiation"
        name = "Solar Radiation"
        value += " kW/m2"
      when "carbon_monoxide"
        name = "Carbon Monoxide"
        value += " %"
      when "humidity"
        name = "Humidity"
        value += " %"
      end

      attribute = { name: name, value: value }
      average_values << attribute
    end

    average_values
  end
end

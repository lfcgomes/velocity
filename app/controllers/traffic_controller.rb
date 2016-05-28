class TrafficController < ApplicationController

  def index
    @conn = Faraday.new(:url => 'http://fiware-porto.citibrain.com/v1/') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    response = @conn.get 'contextEntityTypes/RoadEvent', { key: $api_key }

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
        if attribute['name'] == "street_name"
          puts "*" * 10
          puts attribute['value']
          puts "*" * 10
        end
      end
      if status.present? and name.present?
        street_states[status.to_sym] << name
      end
    end
    render json: street_states
  end
end

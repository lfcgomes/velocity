class EnvironmentController < ApplicationController

  def index
    @conn = Faraday.new(:url => 'http://fiware-porto.citibrain.com/v1/') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    response = @conn.get 'contextEntityTypes/EnvironmentEvent', { key: $api_key, offset: 0, limit: 100 }

    elements = JSON.parse(response.body)['contextResponses']

    attribute_values = {}
    average_values = {}

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
      average_values[element] = (attribute_values[element].map(&:to_f).reduce(:+)/attribute_values[element].size).round(2)
    end

    render json: average_values
  end
end

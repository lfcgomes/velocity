class EnvironmentController < ApplicationController

  def index
    @conn = Faraday.new(:url => 'http://fiware-porto.citibrain.com/v1/') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    response = @conn.post do |req|
      req.url "queryContext?key=#{$api_key}"
      req.headers['Content-Type'] = 'application/json'
      req.body = '{
                    "entities": [
                        {
                            "type": "EnvironmentEvent",
                            "isPattern": "true",
                            "id": ".*"
                        }
                    ],
                    "restriction": {
                        "scopes": [
                            {
                                "type" : "FIWARE::Location",
                                "value" : {
                                    "circle": {
                                        "centerLatitude": "41.178031",
                                        "centerLongitude": "-8.594866",
                                        "radius": "1"
                                    }
                                }
                            }
                        ]
                    }
                }'
    end

    render json: response.body
  end
end

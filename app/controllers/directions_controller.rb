class DirectionsController < ApplicationController

  def index
    conn = Faraday.new(:url => 'https://maps.googleapis.com/maps/api/') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    ## GET ##

    response = conn.get 'directions/json', { origin: "41.168936,-8.590617", destination: "41.142192,-8.614955", mode: "driving", key: "AIzaSyDrYo3wJqcRthZNCdYR4bBYdaI6u4DL_Kc" }
    #raise response.body.inspect

    render json: response.body
  end
end

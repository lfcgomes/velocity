class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  $api_key = 'hackacityporto2016_server'
  $gmaps_key = 'AIzaSyDrYo3wJqcRthZNCdYR4bBYdaI6u4DL_Kc'
end

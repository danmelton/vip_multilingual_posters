require 'rubygems'
require 'open-uri'
require 'geocoder'
require 'json'
require 'sinatra'

API_KEY = ENV['VIP_KEY']

get '/' do
  "Step 1: Enter an Address"
  erb :step1
end

get '/step2' do
  "Step 2: Select a Language"
  session[:address] = params[:address]
  session[:date] = params[:date]
  session[:time1] = params[:time2]
  session[:time2] = params[:time2]
  address = Geocoder.search(params[:address])

  address.first.city
  google_map_image = 
  erb :step2  
end

get '/step3' do
  "Step 3: Download Posters"
  erb :step3
end

def vip(geocoder_object)
  street_number = geocoder_object.address_components_of_type(:street_number).first["long_name"]
  street = geocoder_object.address_components_of_type(:route).first["long_name"]
  city = geocoder_object.city
  state = geocoder_object.state_code
  zip = geocoder_object.postal_code 
  url = URI('http://api.votinginfoproject.org/vip/3.0/GetPollingLocations2')
  params = {
    "house" => street_number,
    "street" => street,
    "city" => city,
    "state"=> state,
    "zip"=> zip,
    "format"=> "json",
    "$expand"=> "Election/State/ElectionAdministration,Locations/PollingLocation/Address,Locations/SourceStreetSegment/NonHouseAddress",
    "key" => API_KEY,
    "onlyUpcoming"=>"false"
  }
  url.query(params)
end

def google_map(latlon)
  "http://maps.googleapis.com/maps/api/staticmap?center="+latlon+"&zoom=16&size=512x512&maptype=roadmap&markers=icon:http://chart.apis.google.com/chart?chst=d_bubble_text_small%26chld=bb%257CVote Here!%257CFFFF88%257C000000|"+latlon+"&sensor=false"
end
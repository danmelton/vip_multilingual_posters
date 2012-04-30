require 'rubygems'
require 'open-uri'
require 'geocoder'
require 'json'
require 'sinatra'
require 'prawn' 
require 'prawn-fillform'

enable :sessions

API_KEY = ENV['VIP_KEY'] || 'FD854C9B-AB50-4652-B5E9-616BA87E165D'

get '/' do
  erb :step1
end

get '/step2' do
  session[:address] = params[:address]
  session[:date] = params[:date]
  session[:time1] = params[:time2]
  session[:time2] = params[:time2]
  address = Geocoder.search(params[:address])
  location = vip_object(address.first)
  session[:polling_name] = location["Address"]["LocationName"]
  session[:polling_ccoordinates] = location["Address"]["Lat"].to_s + "," + location["Address"]["Lon"].to_s
  session[:polling_address1] = location["Address"]["Line1"]
  session[:polling_address2] = location["Address"]["City"] + ", " +location["Address"]["State"] + " " + location["Address"]["Zip"]   
  @languages = load_languages
  erb :step2
end

get '/step3' do
  puts session.inspect
  session[:languages] = params[:language]
  
  data = {}
  data[:page_1] = {}
  data[:page_1][:vote] = { :value => "Vote Now" }
  
  Prawn::Document.generate "poster_language_large.pdf", :template => pdf  do |pdf|
    pdf.fill_form_with(data)
  end
  
  erb :step3
end

get '/download' do
  response.headers['Content-Type'] = "application/pdf"
  send_file 'poster_language_large.pdf'
end

def vip_object(geocoder_object)
  street_number = CGI::escape(geocoder_object.address_components_of_type(:street_number).first["long_name"])
  street = CGI::escape(geocoder_object.address_components_of_type(:route).first["long_name"])
  city = CGI::escape(geocoder_object.city)
  state = CGI::escape(geocoder_object.state_code)
  zip = CGI::escape(geocoder_object.postal_code)   
  url = "http://api.votinginfoproject.org/vip/3.0/GetPollingLocations2?house="+street_number+"&street='"+street+"'&city='"+city+"'&state='"+state+"'&zip='"+zip+"'&%24format=json&$expand=Election/State/ElectionAdministration,Locations/PollingLocation/Address,Locations/SourceStreetSegment/NonHouseAddress&onlyUpcoming=false&key="+API_KEY
  doc = open(url).read
  json_obj = JSON.parse(doc.gsub("\r\n", ""))
  json_obj["d"]["results"].first["Locations"]["results"].first["PollingLocation"]
end


def google_map(latlon)
  "http://maps.googleapis.com/maps/api/staticmap?center="+latlon+"&zoom=16&size=512x512&maptype=roadmap&markers=icon:http://chart.apis.google.com/chart?chst=d_bubble_text_small%26chld=bb%257CVote Here!%257CFFFF88%257C000000|"+latlon+"&sensor=false"
end

def load_languages
  text = File.open("files/languages.yml", "r").read.gsub('"', "")
  text.split(",")
end

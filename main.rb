require 'rubygems'
require 'open-uri'
require 'geocoder'
require 'json'
require 'sinatra'
require 'prawn' 
require 'cgi'
require 'yaml'
require 'prawn-fillform'

enable :sessions

API_KEY = ENV['VIP_KEY'] || 'FD854C9B-AB50-4652-B5E9-616BA87E165D'

get '/' do
  erb :step1
end

get '/step2' do
  session[:address] = params[:address]
  address = Geocoder.search(params[:address])
  location = vip_object(address.first)
  session[:polling_name] = location["Address"]["LocationName"]
  session[:polling_coordinates] = location["Address"]["Lat"].to_s + "," + location["Address"]["Lon"].to_s
  session[:polling_address1] = location["Address"]["Line1"]
  session[:polling_address2] = location["Address"]["City"] + ", " +location["Address"]["State"] + " " + location["Address"]["Zip"]   
  @languages = load_languages
  erb :step2
end

get '/step3' do
  session[:date] = params[:date]
  session[:time1] = params[:time2]
  session[:time2] = params[:time2]  
  session[:languages] = params[:language]
  
  erb :step3
end

get '/download' do
  
  language = params[:language]
  size = params[:size]  
  translations = YAML.load(open('files/translations.yml'))
  
  pdf = Prawn::Document.generate "poster_#{language}_#{size}.pdf", :template => "public/pdfs/#{size}.pdf"  do |pdf|
    pdf.text translations[language]["vote"], size: 120, style: :bold, :text_color => 'FFFFFF', :align => :center
    pdf.text translations[language]["election_date"] + ": " + session[:date], size: 25, style: :bold, :text_color => 'FFFFFF', :align => :center
    pdf.move_down 10    
    pdf.text translations[language]["polling_place"], size: 25, style: :bold, :text_color => 'FFFFFF', :align => :center
    pdf.text session[:polling_name], size: 20, style: :bold, :text_color => 'FFFFFF', :align => :center
    pdf.text session[:polling_address1], size: 20, style: :bold, :text_color => 'FFFFFF', :align => :center
    pdf.move_down 10
    pdf.image open(google_map(session[:polling_coordinates])), :fit => [250, 250], :position => :center
    pdf.move_down 70
    pdf.text translations[language]["more_info"] + " rockthevote.org", size: 20, style: :bold, :text_color => 'FFFFFF', :align => :center
    pdf.text translations[language]["sms"] + " 1-800-000-0000", size: 20, style: :bold, :text_color => 'FFFFFF', :align => :center
  end

  response.headers['Content-Type'] = "application/pdf"
  send_file "poster_#{language}_large.pdf"
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
  "http://maps.googleapis.com/maps/api/staticmap?center="+latlon+"&zoom=16&size=512x512&maptype=roadmap&markers=icon:http://chart.apis.google.com/chart?chst=d_bubble_text_small%26chld=bb%257CVote!%257CFFFF88%257C000000%7c"+latlon+"&sensor=false"
end

def load_languages
  text = File.open("files/languages.yml", "r").read.gsub('"', "")
  text.split(",")
end

require 'rubygems'
require 'sinatra'

get '/' do
  "Step 1: Enter an Address"
  erb :step1
end

get '/step2' do
  "Step 2: Select a Language"
  @languages = load_languages
  erb :step2
end

get '/step3' do
  "Step 3: Download Posters"
  erb :step3
end

def geocode(address)
  Geocoder
end

def load_languages
  text = File.open("files/languages.yml", "r").read.gsub('"', "")
  text.split(",")
end


require 'rubygems'
require 'sinatra'

get '/' do
  "Step 1: Enter an Address"
  erb :step1
end

get '/step2' do
  "Step 2: Select a Language"
  erb :step2  
end

get '/step3' do
  "Step 3: Download Posters"
  erb :step3
end
require 'sinatra'
require 'sinatra/asset_pipeline'

register Sinatra::AssetPipeline

get '/' do
  erb :index
end

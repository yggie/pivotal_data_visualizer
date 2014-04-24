require_relative './pivotal/operations'
require 'bundler'
Bundler.require

PIVOTAL_OPERATIONS = Pivotal::Operations.new(ARGV[0], ARGV[1], project_start_date: ARGV[2], avoid_weekends: true)

set :public_folder, File.dirname(__FILE__) + '/static'

get '/' do
  erb :index
end

get '/blockers' do
  erb :blockers
end

get '/burndown' do
  erb :burndown
end

get '/update_burndown/from/:from/to/:to' do
  PIVOTAL_OPERATIONS.burndown(from: params[:from], to: params[:to])

  redirect "/burndown"
end

get '/update_burndown' do
  PIVOTAL_OPERATIONS.burndown

  redirect "/burndown"
end

get '/update_blockers' do
  PIVOTAL_OPERATIONS.blockers

  redirect '/blockers'
end

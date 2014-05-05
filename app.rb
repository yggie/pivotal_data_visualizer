require_relative './pivotal/operations'
require 'bundler'
Bundler.require

PIVOTAL_OPERATIONS = Pivotal::Operations.new(ARGV[0], ARGV[1], project_start_date: ARGV[2], avoid_weekends: true)

set :public_folder, File.dirname(__FILE__) + '/static'

configure do
  set :burndown_data, {}
end

get '/' do
  erb :index
end

get '/blockers' do
  erb :blockers
end

get '/update_burndown/from/:from/to/:to' do
  @burndown_data = PIVOTAL_OPERATIONS.burndown(from: params["from"], to: params["to"])

  File.open("static/burndown.json", "w") do |f|
    f.write(JSON.dump(@burndown_data.delete("entries")))
  end

  settings.burndown_data = @burndown_data

  redirect "/burndown"
end

get '/update_burndown' do
  @burndown_data = PIVOTAL_OPERATIONS.burndown

  File.open("static/burndown.json", "w") do |f|
    f.write(JSON.dump(@burndown_data.delete("entries")))
  end

  settings.burndown_data = @burndown_data

  redirect "/burndown"
end

get '/burndown' do
  @burndown_data = settings.burndown_data

  erb :burndown
end

get '/update_blockers' do
  PIVOTAL_OPERATIONS.blockers

  redirect '/blockers'
end

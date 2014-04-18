require 'sinatra'
require "open-uri"
require 'json'

TOKEN = ARGV[0]
PROJECT = ARGV[1]

set :public_folder, File.dirname(__FILE__) + '/static'

get '/' do
  erb :index
end

get '/update/:state' do
  state = params[:state] || "started"

  uri = URI.parse("https://www.pivotaltracker.com/services/v5/projects/#{PROJECT}/stories?fields=name%2Ccurrent_state%2Clabels%2Ctasks&with_state=#{state}")
  json_stories = uri.open('X-TrackerToken' => TOKEN) do |f|
    JSON.parse(f.read)
  end

  format = {
    nodes: [],
    edges: []
  }

  count = 0
  stories_x_count = 1

  json_stories.each do |storie|
    stories_x_count += 1
    format[:nodes] << { id: storie["id"].to_s, label: storie["name"], size: 3, x: 0, y: stories_x_count }
    y_axis = stories_x_count
    storie["tasks"].each do |task|
      if !(!!format[:nodes].detect { |node| node[:id] == task["description"] }) && !task["complete"]
        y_axis += 1
        format[:nodes] << { id: task["description"].to_s, label: task["description"], size: 1, x: 1, y: y_axis }
        format[:edges] << { id: "edge#{count += 1}", source: storie["id"].to_s, target: task["description"] }
      end
    end
  end

  File.open("static/data_custom.json","w") do |f|
    f.write(JSON.dump(format))
  end

  redirect '/'
end

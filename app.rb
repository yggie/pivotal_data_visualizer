require 'open-uri'
require 'bundler'
Bundler.require

TOKEN = ARGV[0]
PROJECT = ARGV[1]
PROJECT_START_DATE = ARGV[2]

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

get '/update_burndown' do
  uri = URI.parse("https://www.pivotaltracker.com/services/v5/projects/#{PROJECT}/stories?fields=estimate%2Ccurrent_state%2Caccepted_at")

  json_stories = uri.open('X-TrackerToken' => TOKEN) do |f|
    JSON.parse(f.read)
  end
  entries = []

  total_story_points = json_stories.inject(0) do |total, each|
    total += (each["estimate"]) ? each["estimate"] : 0
  end

  entries << { date: PROJECT_START_DATE, points: total_story_points }

  json_stories.each do |story|
     entries << {
       date: story["accepted_at"],
       points: total_story_points -= story["estimate"]
     } if story["current_state"] == "accepted" && story["estimate"]
  end

  File.open("static/burndown.json","w") do |f|
    f.write(JSON.dump(entries))
  end

  redirect "/burndown"
end

get '/update_blockers/:state' do
  state = params[:state] || "started"

  uri = URI.parse("https://www.pivotaltracker.com/services/v5/projects/#{PROJECT}/stories?fields=name%2Cestimate%2Ccurrent_state%2Clabels%2Ctasks&with_state=#{state}")
  json_stories = uri.open('X-TrackerToken' => TOKEN) do |f|
    JSON.parse(f.read)
  end

  g = GraphViz.new( :G, :type => :digraph )
  nodes = {}

  json_stories.each do |story|
    nodes["##{story["id"]}"] = { node: g.add_nodes(story["name"]), tasks: story["tasks"] }
  end

  nodes.each do |key, value|
    source = value[:node]
    value[:tasks].each do |task|
      if !task["complete"] && nodes[task["description"]]
        target = nodes[task["description"]]
        g.add_edges(source, target[:node])
      elsif !task["complete"] && nodes[task["description"]].nil?
        new_target = g.add_nodes(task["description"])
        g.add_edges(source, new_target)
      end
    end
  end

  g.output(:png => "static/blockers.png")

  redirect '/blockers'
end

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
  from_date = Date.parse(PROJECT_START_DATE)

  uri = URI.parse("https://www.pivotaltracker.com/services/v5/projects/#{PROJECT}/stories?fields=estimate%2Ccurrent_state%2Caccepted_at")
  json_stories = uri.open('X-TrackerToken' => TOKEN) do |f|
    JSON.parse(f.read)
  end

  entries = []

  # Build the graph chronologically
  to_date = Date.today
  chronology_dates = (from_date..to_date).map { |date| date.to_s }
  chronology = Hash[chronology_dates.zip Array.new(chronology_dates.count, 0)]

  # Build the first entry that will represent the first peack
  # on the chart
  total_story_points = 0

  json_stories.each do |story|
    total_story_points += (story["estimate"]) ? story["estimate"] : 0

    if story["current_state"] == "accepted" && story["estimate"]
      story_date = Date.parse(story["accepted_at"]).to_s
      chronology[story_date] += story["estimate"]
    end
  end

  entries << { date: from_date.to_s, points: total_story_points }

  chronology.each do |date, points|
     entries << {
       date: date,
       points: total_story_points -= points
     }
  end

  File.open("static/burndown.json","w") do |f|
    f.write(JSON.dump(entries))
  end

  redirect "/burndown"
end

get '/update_blockers' do
  uri = URI.parse("https://www.pivotaltracker.com/services/v5/projects/#{PROJECT}/stories?fields=name%2Cestimate%2Ccurrent_state%2Clabels%2Ctasks")
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

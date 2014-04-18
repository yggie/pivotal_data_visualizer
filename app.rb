require 'sinatra'
require 'open-uri'
require 'json'

TOKEN = ARGV[0]
PROJECT = ARGV[1]

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

  entries << { date: "2014-03-01T00:00:00Z", points: total_story_points }

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

  format = {
    nodes: [],
    edges: []
  }

  count = 0
  stories_x_count = 0

  json_stories.each do |story|
    stories_x_count += 1

    format[:nodes] << {
      id: story["id"].to_s,
      label: story["name"],
      size: story["estimate"],
      x: 0,
      y: stories_x_count 
    }

    y_axis = stories_x_count

    story["tasks"].each do |task|
      task_node_exists = !!format[:nodes].detect { |node| node[:id] == task["description"] }

      if !task_node_exists && !task["complete"]
        y_axis += 1

        format[:nodes] << {
          id: task["description"].to_s,
          label: task["description"],
          size: 1,
          x: 1,
          y: y_axis / 2.0
        }

        format[:edges] << {
          id: "edge#{count += 1}",
          source: story["id"].to_s,
          target: task["description"]
        }
      end
    end
  end

  File.open("static/data_custom.json","w") do |f|
    f.write(JSON.dump(format))
  end

  redirect '/blockers'
end

require 'open-uri'

module Pivotal
  class Operations
    def initialize(token, project, options = {})
      @token = token
      @project = project
      @options = options
    end

    def stories(filter)
      uri = URI.parse("https://www.pivotaltracker.com/services/v5/projects/#{@project}/stories#{filter}")
      uri.open('X-TrackerToken' => @token) do |f|
        JSON.parse(f.read)
      end
    end

    def burndown(args = {})
      json_stories = stories("?fields=estimate%2Ccurrent_state%2Caccepted_at%2Ccreated_at")

      entries = []
      from_date = Date.parse(args.fetch(:from, @options[:project_start_date]))
      to_date = Date.parse(args.fetch(:to, Date.today.to_s))

      # Build the graph chronologically
      chronology_dates = (from_date..to_date).map { |date| date.to_s }

      # Getting rid of the first entry sisnce that is processed separately
      chronology = Hash[chronology_dates.zip Array.new(chronology_dates.count, 0)]

      total_story_points = 0

      json_stories.each do |story|
        if story["current_state"] == "accepted"
          story_accept_date = Date.parse(story["accepted_at"])

          if story["estimate"] && story_accept_date >= from_date && story_accept_date <= to_date
            total_story_points += story["estimate"]
            chronology[story_accept_date.to_s] += story["estimate"]
          end
        end
      end

      chronology.each do |date, points|
         entries << {
           date: date,
           points: total_story_points -= points
         }
      end

      File.open("static/burndown.json","w") do |f|
        f.write(JSON.dump(entries))
      end
    end

    def blockers
      json_stories = stories("?fields=name%2Cestimate%2Ccurrent_state%2Clabels%2Ctasks%2Cestimate%2Caccepted_at")

      g = GraphViz.new( :G, :type => :digraph )
      nodes = {}

      json_stories.each do |story|
        nodes["##{story["id"]}"] = { node: g.add_nodes(story["name"]), tasks: story["tasks"] } if story["estimate"] && !story["accepted_at"]
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
    end
  end
end

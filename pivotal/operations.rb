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
      @burndow_json_stories = stories("?fields=estimate%2Cstory_type%2Ccurrent_state%2Caccepted_at%2Cname")

      from_date = Date.parse(args.fetch(:from, @options[:project_start_date]))
      to_date = Date.parse(args.fetch(:to, Date.today.to_s))

      # Build the graph chronologically
      chronology_dates = (from_date..to_date)
      chronology_dates = chronology_dates.select { |date| !date.saturday? && !date.sunday? } if @options[:avoid_weekends]
      chronology_dates = chronology_dates.map { |date| date.to_s }

      chronology = Hash[chronology_dates.zip Array.new(chronology_dates.count, 0)]

      total_story_points = 0
      stories_statistics = {}
      entries = []

      @burndow_json_stories.each do |story|
        stories_statistics[story["current_state"]] ||= []
        if story["story_type"] == "feature" && story["current_state"] != "accepted"
          stories_statistics[story["current_state"]] << story
        end

        story["estimate"] ||= -1

        ## Build burndown chronology data
        if story["current_state"] == "accepted"
          story_accept_date = Date.parse(story["accepted_at"])

          if story["estimate"] >= 0 && story_accept_date >= from_date && story_accept_date <= to_date
            stories_statistics[story["current_state"]] << story
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

      stories_statistics["entries"] = entries

      stories_statistics
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

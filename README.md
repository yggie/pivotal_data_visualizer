pivotal_data_visualizer
=======================

A simple web app to visualise pivotal storie data.

How does it work
================

###Burndown chart

It shows all accepted stories progression by date. The first point is the result
of summing up all the estimated stories and the first date is a fix moment in time
(project start date).

The information is group by date.

To refresh the information, access `/update_burndown`.

###Story task graph (blockers)

At work we have faced situations where stories tend to be related to one another and when the amount of relations between them grow, it gets hard to visualize that.

This graph needs some work from the way we present the information at Pivotal, and here is a small example.

Let's say we have a story A, B and C. Now, A depends on B and C, B has no dependecies, and C depends on A. How can we present this information at Pivotal? Well my answer was Tasks:

A has the following tasks:
* #b_id (unfinished)
* #c_id (unfinished)

B has other non story related tasks
* fix extrapolation

C has the following tasks
* #a_id (unfinished)

Then we will need to update the graph from our app accessing `/update_blockers/started` on the browser. That will fetch the information from Pivotal and rebuild the graph.

It will look like this:

![preview](http://i.imgur.com/DWZ70qO.png)

So the advantage of using tasks is that once we decide that one of the edges between stories is no longer needed, we can set the story as finished, removing the link on the graph.

To refresh the graph, access `/update_blockers/started`

Note: This will only work for stories that are in `started` state. The graph data can be filtered by state.

###Runnign the server

```ruby
bundle exec ruby app.rb TOKEN PROJECT_ID PROJECT_START_DATETIME
```

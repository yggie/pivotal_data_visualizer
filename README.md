pivotal_data_visualizer
=======================

A simple web app to visualise pivotal storie data.

How does it work
================

###Burndown chart

It shows all accepted stories progression by date. The first point is the result
of summing up all the estimated stories and the first date is a fix moment in time
(project start date).

###Story task graph (blockers)

It shows how stories and tasks relate. This is particulary useful to find
blocking tasks between stories.


###Runnign the server

```ruby
bundle exec ruby app.rb TOKEN PROJECT_ID PROJECT_START_DATETIME
```

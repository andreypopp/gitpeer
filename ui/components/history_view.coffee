###*

  History view

  @jsx core.DOM

###

Timestamp = require 'react-time'
core = require './core'
CommitLine = require './commit_line'
NextPrevPager = require './next_prev_pager'

sameDay = (a, b) ->
  return false unless b?
  a.getYear() == b.getYear() \
    and a.getMonth() == b.getMonth() \
    and a.getDate() == b.getDate()

module.exports = core.createComponent
  render: ->
    model = this.getModel()
    date = undefined
    elements = []
    commits = for commit in model.commits.models
      unless sameDay(commit.author.time, date)
        elements.push `<div class="date">
            <Timestamp value={commit.author.time} format="%Y/%m/%d" />
          </div>`
      date = commit.author.time
      elements.push `<CommitLine notime nomessage model={commit} />`
    `<div class="HistoryView">
      <NextPrevPager model={model} nextLabel="Older commits" prevLabel="Newer commits" />
      <div class="commits">{elements}</div>
      <NextPrevPager model={model} nextLabel="Older commits" prevLabel="Newer commits" />
     </div>`


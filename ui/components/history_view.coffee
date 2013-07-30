###*

  History view

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
{createComponent} = require './core'
CommitLine = require './commit_line'

sameDay = (a, b) ->
  return false unless b?
  a.getYear() == b.getYear() \
    and a.getMonth() == b.getMonth() \
    and a.getDate() == b.getDate()

module.exports = createComponent

  next: ->
    this.getModel().fetchNext()

  prev: ->
    this.getModel().fetchPrev()

  $pager: ->
    model = this.getModel()
    if model.pagination?
      next = if model.pagination.next
        `<a class="next" href={model.urlNext()}>
          <i class="icon-long-arrow-down"></i> older
         </a>`
      prev = if model.pagination.prev
        `<a class="prev" href={model.urlPrev()}>
          <i class="icon-long-arrow-up"></i> newer
         </a>`
      `<div class="pager">{next}{prev}</div>`

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
      {this.$pager()}
      <div class="commits">{elements}</div>
      {this.$pager()}
     </div>`


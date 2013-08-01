###*

  Issues view

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
{createComponent} = require './core'

IssueItemView = createComponent
  render: ->
    model = this.getModel()
    href = "/issues/#{model.id}"
    `<a href={href} class="IssueItemView">
      <span class="name">{model.name}</span>
      <Timestamp value={model.updated} relative />
     </a>`

module.exports = createComponent
  render: ->
    model = this.getModel()
    issues = for issue in model.issues.models
      IssueItemView(model: issue)
    `<div class="IssuesView">
      <div class="meta">
        <div class="state-selector">
          <a>opened ({model.stats.opened})</a>
          <a>closed ({model.stats.closed})</a>
        </div>
        <a href="/issues/new" class="new-issue"><i class="icon icon-plus"></i> New issue</a>
      </div>
      <div class="issues">{issues}</div>
     </div>`

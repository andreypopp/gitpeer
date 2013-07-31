###*

  Blob view

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
{createComponent} = require './core'

IssueView = createComponent
  render: ->
    model = this.getModel()
    `<a class="IssueView">
      <span class="name">{model.name}</span>
      <Timestamp value={model.updated} relative />
     </a>`

module.exports = createComponent
  render: ->
    model = this.getModel()
    issues = for issue in model.issues.models
      IssueView(model: issue)
    `<div class="IssuesView">
      <div class="meta">
        <a>opened ({model.stats.opened})</a>
        <a>closed ({model.stats.closed})</a>
      </div>
      <div class="issues">{issues}</div>
     </div>`

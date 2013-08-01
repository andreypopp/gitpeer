###*

  Issues view

  @jsx core.DOM

###

Timestamp = require 'react-time'
core = require './core'

IssueItemView = core.createComponent
  render: ->
    model = this.getModel()
    href = "/issues/#{model.id}"
    `<a href={href} class="IssueItemView">
      <span class="name">{model.name}</span>
      <Timestamp value={model.updated} relative />
     </a>`

module.exports = core.createComponent
  render: ->
    model = this.getModel()
    issues = for issue in model.issues.models
      IssueItemView(model: issue)
    `<div class="IssuesView">
      <div class="meta">
        <div class="state-selector">
          <a>opened ({model.stats.opened || 0})</a>
          <a>closed ({model.stats.closed || 0})</a>
        </div>
        <a href="/issues/new" class="new-issue"><i class="icon icon-plus"></i> New issue</a>
      </div>
      <div class="issues">{issues}</div>
     </div>`

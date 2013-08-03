###*

  Issues view

  @jsx core.DOM

###

Timestamp = require 'react-time'
uriTemplate = require 'uri-template'
core = require './core'

IssueItemView = core.createComponent
  render: ->
    model = this.getModel()
    href = "/issues/#{model.id}"
    `<a href={href} class="IssueItemView">
      <span class="id">{model.id}</span>
      <span class="name">{model.name}</span>
      <Timestamp value={model.updated} relative />
     </a>`

module.exports = core.createComponent
  stateURI: (state) ->
    uriTemplate.parse(this.getModel()._links.filtered_html.href)
      .expand(state: state)

  stateSwitch: (state) ->
    model = this.getModel()
    `<a href={this.stateURI(state)}>{state} ({model.stats[state] || 0})</a>`

  render: ->
    model = this.getModel()
    issues = for issue in model.issues.models
      IssueItemView(model: issue)
    `<div class="IssuesView">
      <div class="meta">
        <div class="Controls">
          <a href="/issues/new" class="new-issue"><i class="icon icon-plus"></i> New issue</a>
        </div>
        <div class="state-selector">
          {this.stateSwitch('opened')}
          {this.stateSwitch('closed')}
        </div>
      </div>
      <div class="issues">{issues}</div>
     </div>`

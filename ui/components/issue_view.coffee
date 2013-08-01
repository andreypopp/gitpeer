###*

  Issues view

  @jsx core.DOM

###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
core = require './core'
IssueEditor = require './issue_editor'

IssueView = core.createComponent
  render: ->
    model = this.getModel()
    `<div class="Issue">
      <h3>{model.name}</h3>
      <p>{model.body}</p>
     </div>`

module.exports = core.createComponent

  $stateToggle: ->
    model = this.getModel()
    if model.state == 'opened'
      `<a onClick={this.onStateToggle} class="close"><i class="icon icon-ok"></i> Close</a>`
    else if model.state == 'closed'
      `<a onClick={this.onStateToggle} class="close"><i class="icon icon-exclamation"></i> Reopen</a>`

  $controls: ->
    issueView = if this.state?.edit
      [`<a onClick={this.onEditSave} class="edit"><i class="icon icon-ok"></i> Save</a>`,
      `<a onClick={this.onEditCancel} class="remove"><i class="icon icon-remove"></i> Cancel</a>`]
    else
      [this.$stateToggle(),
      `<a onClick={this.onEditStart} class="edit"><i class="icon icon-pencil"></i> Edit</a>`,
      `<a onClick={this.onRemove} class="remove"><i class="icon icon-trash"></i> Remove</a>`]

  onStateToggle: ->
    model = this.getModel()
    if model.state == 'opened'
      model.save({state: 'closed'}, patch: true)
    else if model.state == 'closed'
      model.save({state: 'opened'}, patch: true)

  onRemove: ->
    this.getModel().destroy().then =>
      GitPeer.router.navigate("/issues", trigger: true)

  onEditStart: ->
    this.setState(edit: true)

  onEditCancel: ->
    this.setState(edit: false)

  onEditSave: ->
    this.getModel()
      .save(this.refs.editor.values(), patch: true)
      .then => this.setState(edit: false)

  render: ->
    model = this.getModel()
    issueView = if this.state?.edit
      IssueEditor(model: model, ref: 'editor')
    else
      IssueView(model: model)
    `<div class="IssueView">
      <div class="Controls">{this.$controls()}</div>
      {issueView}
     </div>`

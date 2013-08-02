###*

  Issues view

  @jsx core.DOM

###

Timestamp = require 'react-time'
core = require './core'
IssueEditor = require './issue_editor'
Control = require './control'

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
      Control(label: 'Close', icon: 'ok', onClick: this.onStateToggle)
    else if model.state == 'closed'
      Control(label: 'Reopen', icon: 'exclamation', onClick: this.onStateToggle)

  $controls: ->
    issueView = if this.state?.edit
      [Control(label: 'Save', icon: 'ok', onClick: this.onEditSave),
       Control(label: 'Cancel', icon: 'remove', onClick: this.onEditCancel)]
    else
      [this.$stateToggle(),
       Control(label: 'Edit', icon: 'pencil', onClick: this.onEditStart),
       Control(label: 'Remove', icon: 'trash', onClick: this.onRemove)]

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

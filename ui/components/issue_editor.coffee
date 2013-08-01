###*

  Issue editor

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
$ = require 'jqueryify'
require 'jquery-autosize/jquery.autosize'
{createComponent} = require './core'

module.exports = createComponent

  componentDidMount: ->
    $body = $(this.refs.body.getDOMNode())
    $body.autosize()

  onCancel: ->
    window.history.back()

  onCreate: ->
    model = this.getModel()
    model.name = this.refs.name.getDOMNode().value
    model.body = this.refs.body.getDOMNode().value
    model.save()
    GitMan.app.show(model)

  render: ->
    model = this.getModel()
    `<div class="IssueEditor">
      <input ref="name" class="name" placeholder="Issue name" type="text" value={model.name} />
      <textarea ref="body" placeholder="description">{model.body}</textarea>
      <div class="controls">
        <a onClick={this.onCreate} class="save"><i class="icon icon-plus"></i> Create</a>
        <a onClick={this.onCancel} class="cancel"><i class="icon icon-remove"></i> Cancel</a>
      </div>
     </div>`

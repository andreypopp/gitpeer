###*

  Issue editor

  @jsx core.DOM

###

$ = require 'jqueryify'
require 'jquery-autosize/jquery.autosize'
core = require './core'

module.exports = core.createComponent

  componentDidMount: ->
    $body = $(this.refs.body.getDOMNode())
    $body.autosize()

  values: ->
    name = this.refs.name.getDOMNode().value
    body = this.refs.body.getDOMNode().value
    {name, body}

  render: ->
    model = this.getModel()
    `<div class="IssueEditor">
      <input ref="name" class="name" placeholder="Issue name" type="text" value={model.name} />
      <textarea ref="body" class="body" placeholder="Describe issue">{model.body}</textarea>
     </div>`

###*

  Issue editor

  @jsx core.DOM

###

$ = require 'jqueryify'
require 'jquery-autosize/jquery.autosize'
require '../vendor/selectize'
core = require './core'

module.exports = core.createComponent

  componentDidMount: ->
    $body = $(this.refs.body.getDOMNode())
    $body.autosize()
    $tags = $(this.refs.tags.getDOMNode())
    $tags.selectize(create: true, plugins: ['remove_button'])

  values: ->
    name = this.refs.name.getDOMNode().value
    body = this.refs.body.getDOMNode().value
    {name, body}

  render: ->
    model = this.getModel()
    `<div class="IssueEditor">
      <input ref="name" class="name" placeholder="Issue name" type="text" value={model.name} />
      <textarea ref="body" class="body" placeholder="Describe issue">{model.body}</textarea>
      <select ref="tags" placeholder="Add tags" multiple>
        <option value="United States">United States</option>
        <option value="United Kingdom">United Kingdom</option>
        <option value="Afghanistan">Afghanistan</option>
        <option value="Aland Islands">Aland Islands</option>
        <option value="Albania">Albania</option>
      </select>
     </div>`

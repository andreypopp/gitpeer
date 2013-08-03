###*

  Issue editor

  @jsx core.DOM

###

$ = require 'jqueryify'
require 'jquery-autosize/jquery.autosize'
core = require './core'
TagSelector = require './tag_selector'

module.exports = core.createComponent

  componentDidMount: ->
    $body = $(this.refs.body.getDOMNode())
    $body.autosize()
    $tags = $(this.refs.tags.getDOMNode())
    $tags.selectize(create: true, plugins: ['remove_button'])

  values: ->
    name: this.refs.name.getDOMNode().value
    body: this.refs.body.getDOMNode().value
    tags: this.refs.tags.values()

  render: ->
    model = this.getModel()
    `<div class="IssueEditor">
      <input ref="name" class="name" placeholder="Issue name" type="text" value={model.name} />
      <textarea ref="body" class="body" placeholder="Describe issue">{model.body}</textarea>
      <TagSelector ref="tags" model={model.tags} />
     </div>`

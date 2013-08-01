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

  onCancel: ->
    window.history.back()

  onCreate: ->
    model = this.getModel()
    model.name = this.refs.name.getDOMNode().value
    model.body = this.refs.body.getDOMNode().value
    model.save().then (model) =>
      GitPeer.router.navigate(model._links.self_html.href, trigger: true)

  render: ->
    model = this.getModel()
    `<div class="IssueEditor">
      <form>
        <input ref="name" class="name" placeholder="Issue name" type="text" value={model.name} />
        <textarea ref="body" class="body" placeholder="Describe issue">{model.body}</textarea>
      </form>
      <div class="controls">
        <a onClick={this.onCreate} class="save"><i class="icon icon-plus"></i> Create</a>
        <a onClick={this.onCancel} class="cancel"><i class="icon icon-remove"></i> Cancel</a>
      </div>
     </div>`

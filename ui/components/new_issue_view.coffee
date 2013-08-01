###*

  New issue view

  @jsx core.DOM

###

$ = require 'jqueryify'
require 'jquery-autosize/jquery.autosize'
core = require './core'
IssueEditor = require './issue_editor'

module.exports = core.createComponent

  onCancel: ->
    GitPeer.router.navigate('/issues', trigger: true)

  onCreate: ->
    values = this.refs.editor.values()
    this.getModel().save(values).then (model) =>
      GitPeer.router.navigate(model._links.self_html.href, trigger: true)

  render: ->
    model = this.getModel()
    `<div class="NewIssueView">
      <IssueEditor ref="editor" model={model} />
      <div class="Controls">
        <a onClick={this.onCreate} class="save"><i class="icon icon-plus"></i> Create</a>
        <a onClick={this.onCancel} class="cancel"><i class="icon icon-remove"></i> Cancel</a>
      </div>
     </div>`

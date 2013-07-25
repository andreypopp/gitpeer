###*
  @jsx React.DOM
###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
{Filtered} = require 'backbone.projections/filtered'

{createComponent} = require './core.coffee'
{CommentsView, CommentEditor} = require './comments.coffee'
{DiffView} = require './diff.coffee'

CommitStatus = createComponent

  getInitialState: ->
    showMessage: not this.props.nomessage?

  onClick: ->
    this.setState(showMessage: not this.state?.showMessage)

  formatMessage: (commit) ->
    [headline, message] = commit.message.split('\n\n')
    if message
      message = message
        .split('\n')
        .filter(Boolean)
        .map (line) -> `<p>{line}</p>`
    {headline, message}

  render: ->
    model = this.getModel()
    time = unless this.props.notime
      `<div class="time">
        authored <Timestamp value={model.author.time} relative />
       </div>`
    {headline, message} = this.formatMessage(model)

    showMessage = message? and (
        not this.props.nomessage? and
        this.state?.showMessage or
        this.state?.showMessage)

    `<div onClick={this.onClick} class="CommitStatus">
      <div class="head">
        <div class="sha">{model.id.substring(0, 6)}</div>
        <div class="headline">
          <a href={model._links.self_html.href}>{headline}</a>
        </div>
        <div class="author">{model.author.name}</div>
        {time}
      </div>
      {showMessage && <div class="message">{message}</div>}
     </div>`

CommitView = createComponent
  onComment: (comment) ->
    model = this.getModel()
    comment.object_id = model.id
    model.comments.create(comment)

  render: ->
    model = this.getModel()

    if this.props.comments
      commitComments = new Filtered model.comments,
        filter: (m) -> not m.position?
      diffComments = new Filtered model.comments,
        filter: (m) -> m.position?
      model.comments.fetch(reset: true)

    `<div class="CommitView">
      <CommitStatus model={model} />
      <DiffView model={model.diff} onComment={this.onComment} comments={diffComments} />
      {this.props.comments && <CommentsView model={commitComments} />}
      {this.props.comments && <CommentEditor autosize
        placeholder="comment on commit..."
        onComment={this.onComment} />}
     </div>`

module.exports = {CommitStatus, CommitView}

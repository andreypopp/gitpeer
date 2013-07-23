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
  render: ->
    model = this.getModel()
    time = unless this.props.skipTime
      `<div class="time">
        authored <Timestamp value={model.author.time} relative />
       </div>`

    `<div class="CommitStatus">
      <div class="sha">{model.id.substring(0, 6)}</div>
      <div class="message">
        <a href={model._links.self_html.href}>{model.message}</a>
      </div>
      <div class="author">{model.author.name}</div>
      {time}
     </div>`

CommitView = createComponent
  onComment: (comment) ->
    model = this.getModel()
    comment.object_id = model.id
    model.comments.create(comment)

  render: ->
    model = this.getModel()
    model.comments.fetch(reset: true)
    commitComments = new Filtered model.comments,
      filter: (m) -> not m.position?
    diffComments = new Filtered model.comments,
      filter: (m) -> m.position?
    `<div class="CommitView">
      <CommitStatus model={model} />
      <DiffView model={model.diff} onComment={this.onComment} comments={diffComments} />
      <CommentsView model={commitComments} />
      <CommentEditor autosize
        placeholder="comment on commit..."
        onComment={this.onComment} />
     </div>`

module.exports = {CommitStatus, CommitView}

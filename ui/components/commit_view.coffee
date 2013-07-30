###*

  Render commit summary in a line

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
{Filtered} = require 'backbone.projections/filtered'

{createComponent} = require './core'
DiffView = require './diff_view'
CommitLine = require './commit_line'
CommentEditor = require './comment_editor'
CommentsView = require './comments_view'

module.exports = createComponent

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
      <CommitLine model={model} />
      <DiffView model={model.diff} onComment={this.onComment} comments={diffComments} />
      {this.props.comments && <CommentsView model={commitComments} />}
      {this.props.comments && <CommentEditor autosize
        placeholder="comment on commit..."
        onComment={this.onComment} />}
     </div>`

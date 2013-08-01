###*

  Comments view

  @jsx core.DOM

###

Timestamp = require 'react-time'

core = require './core'
{Comment} = require '../models'

CommentView = core.createComponent

  onMouseEnter: ->
    this.props.onMouseEnter?(this.getModel(), this)

  onMouseLeave: ->
    this.props.onMouseLeave?(this.getModel(), this)

  render: ->
    model = this.getModel()
    `<div class="CommentView"
        onMouseEnter={this.onMouseEnter}
        onMouseLeave={this.onMouseLeave}>
      <div class="content">{model.content}</div>
      <div class="meta">
        <span class="author">{model.author.name}</span>
        <Timestamp value={model.created} relative />
      </div>
     </div>`

module.exports = core.createComponent

  render: ->
    model = this.getModel()
    comments = model.map (comment) =>
      CommentView
        model: comment
        onMouseEnter: this.props.onMouseEnter
        onMouseLeave: this.props.onMouseLeave
    `<div class="CommentsView">{comments}</div>`

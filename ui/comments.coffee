###*
  @jsx React.DOM
###

React = require 'react-tools/build/modules/react'
{createComponent} = require './core.coffee'
{Comment} = require './models.coffee'
Timestamp = require 'react-time'

CommentEditor = createComponent

  onSubmit: ->
    comment = new Comment
      author: GitMan.user
      content: this.refs.comment.getDOMNode().value
      created: new Date
    this.props.onComment?(comment)

  onKeyPress: ->
    value = this.refs.comment.getDOMNode().value
    this.props.onUpdate?(value)

  onCancel: ->
    value = this.refs.comment.getDOMNode().value
    this.refs.comment.getDOMNode().value = ''
    this.props.onCancel?(value)

  componentDidMount: ->
    $comment = $(this.refs.comment.getDOMNode())
    $comment.autosize() if this.props.autosize
    $comment.focus() if this.props.autofocus

  render: ->
    placeholder = this.props.placeholder or "enter your comment..." 
    `<div class="CommentEditor">
      <textarea onKeyPress={this.onKeyPress} placeholder={placeholder} ref="comment">
        {this.props.value}
      </textarea>
      <button class="tiny success" onClick={this.onSubmit}>
        <i class="icon-pencil"></i> comment
      </button>
      <button class="tiny secondary" onClick={this.onCancel}>
        <i class="icon-remove"></i> cancel
      </button>
     </div>`

CommentsView = createComponent

  render: ->
    model = this.getModel()
    comments = model.map (comment) =>
      CommentView
        model: comment
        onMouseEnter: this.props.onMouseEnter
        onMouseLeave: this.props.onMouseLeave
    `<div class="CommentsView">{comments}</div>`

CommentView = createComponent

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

module.exports = {CommentEditor, CommentsView, CommentView}

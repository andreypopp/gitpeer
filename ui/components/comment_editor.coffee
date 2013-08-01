###*

  Comment editor

  @jsx core.DOM

###

$ = require 'jqueryify'
require 'jquery-autosize/jquery.autosize'

core = require './core'

module.exports = core.createComponent

  onSubmit: ->
    comment = new Comment
      author: GitMan.user # TODO: get rid of global state
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

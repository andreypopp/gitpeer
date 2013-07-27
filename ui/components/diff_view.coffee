###*

  UI components:

      DiffView (HasComments)
      |
      `- PatchView (HasComments)
          |
          `- HunkView (HasComments)
              |
              |- LineView
              `- SelectedLineRangeView
                  |
                  `- LineView

  Mixins:

  - HasComments - objects which accepts comments property and react on changes
    in it

  Controllers:

  - LineSelection - tracking hunk's selection state

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
{Filtered} = require 'backbone.projections/filtered'
{contains} = require 'underscore'

{createComponent} = require './core.coffee'
CommentEditor = require './comment_editor.coffee'
CommentsView = require './comments_view.coffee'

HasComments =
  componentDidMount: ->
    this.observe(this.props.comments) if this.props.comments

module.exports = createComponent
  mixins: [HasComments]

  render: ->
    patches = this.getModel().map (patch) =>
      if this.props.comments
        comments = new Filtered this.props.comments,
          filter: (m) -> m.position?.patch == patch.delta.new_file.path
      PatchView(model: patch, onComment: this.props.onComment, comments: comments)
    `<div class="DiffView">{patches}</div>`

PatchView = createComponent
  mixins: [HasComments]

  onComment: (comment) ->
    comment.position.patch = this.getModel().delta.new_file.path
    this.props.onComment?(comment)

  render: ->
    model = this.getModel()

    hunks = model.hunks.map (hunk) =>
      if this.props.comments
        comments = new Filtered this.props.comments,
          filter: (m) -> m.position?.hunk == hunk.header
      HunkView(model: hunk, onComment: this.onComment, comments: comments)

    `<div class="PatchView">
      <div class="meta">
        {model.delta.new_file.path}
      </div>
      <div class="hunks">{hunks}</div>
     </div>`

HunkView = createComponent
  mixins: [HasComments]

  getInitialState: ->
    selection: []
    highlight: []
    comment: null

  onLineSelect: (line, isRange) ->
    hunk = this.getModel()
    idx = hunk.lines.indexOf(line)
    this.selection.update(idx, isRange)

  onCommentMouseEnter: (comment) ->
    this.setState(highlight: comment.position.lines)

  onCommentMouseLeave: (comment) ->
    this.setState(highlight: [])

  onCommentUpdate: (value) ->
    if value == null
      this.comment = null
      this.forceUpdate()
    else if value == '' and not this.comment?
      this.comment = value
      this.forceUpdate()
    else if value.length > 0 and this.comment?
      this.comment = value

  onComment: (comment) ->
    lines = this.selection.slice(this.getModel().lines)
    comment.position =
      lines: lines.map(lineKey)
      hunk: this.getModel().header
    this.props.onComment?(comment)

  render: ->
    hunk = this.getModel()
    this.selection = new LineSelection(this)
    this.comments = this.props.comments
    lines = hunk.lines.slice(0)

    if this.selection.isRange()
      {start, end} = this.selection
      lines.splice(this.selection.start, 0, lines.splice(start, end - start + 1))

    lines = lines.map (line) =>
      idx = hunk.lines.indexOf(line)
      if Array.isArray line
        SelectedLineRangeView
          model: line
          hunk: this
      else
        LineView
          key: lineKey(line)
          model: line
          hunk: this
          selected: this.selection.contains(idx)

    `<div class="HunkView">
      <div class="header">{hunk.header}</div>
      <div class="lines">{lines}</div>
     </div>`

LineView = createComponent
  onClick: (e) ->
    this.props.hunk.onLineSelect(this.getModel(), e.nativeEvent.shiftKey)

  onComment: (comment) ->
    this.hideCommentEditor()
    this.props.hunk.onComment(comment)

  isCommentEditorShown: ->
    this.props.hunk.comment? and this.props.selected

  hideCommentEditor: ->
    this.props.hunk.onCommentUpdate?(null)

  showCommentEditor: ->
    this.props.hunk.onCommentUpdate?('')
    if not this.props.selected
      this.props.hunk.onLineSelect(this.getModel(), false)

  toggleCommentEditor: ->
    if this.isCommentEditorShown()
      this.hideCommentEditor()
    else
      this.showCommentEditor()

  render: ->
    model = this.getModel()
    lineClass = """
      LineView
      #{contains(this.props.hunk.state.highlight, this.props.key) and 'highlighted' or ''}
      #{model.line_origin}
      #{this.props.selected and 'selected' or ''}
    """

    commentsEnabled = this.props.hunk.comments?

    if commentsEnabled
      comments = this.props.hunk.comments.filter (comment) =>
        m = comment.position.lines[comment.position.lines.length - 1]
        lineKey(this.getModel()) == m

      commentsView = if comments.length > 0
        CommentsView
          model: comments
          onMouseEnter: this.props.hunk.onCommentMouseEnter
          onMouseLeave: this.props.hunk.onCommentMouseLeave

      editorView = if this.isCommentEditorShown()
        CommentEditor
          autosize: true
          autofocus: true
          value: this.props.hunk.comment
          onComment: this.onComment
          onUpdate: this.props.hunk.onCommentUpdate
          onCancel: this.hideCommentEditor

    lineComments = if commentsView or editorView
      `<div class="line-comments">{commentsView}{editorView}</div>`

    `<div class={lineClass}>
      <div class="line">
        <span onClick={this.onClick}>
          <pre>
            <code class="old_lineno">{model.old_lineno > 0 ? model.old_lineno : ''}</code>
            <code class="new_lineno">{model.new_lineno > 0 ? model.new_lineno : ''}</code>
            <code class="content">{model.content}</code>
          </pre>
        </span>
        <div class="toolbar">
          {commentsEnabled && <a onClick={this.toggleCommentEditor}><i class="icon-pencil"></i></a>}
        </div>
      </div>
      {lineComments}
     </div>`

SelectedLineRangeView = createComponent

  render: ->
    lines = for line in this.getModel()
      LineView
        key: lineKey(line)
        model: line
        hunk: this.props.hunk
        selected: true

    `<div class="lines SelectedLineRangeView">
      <div class="range">{lines}</div>
     </div>`

class LineSelection

  constructor: (hunk, selection) ->
    this.hunk = hunk
    this.selection = selection or hunk.state?.selection or []
    this.start = this.selection[0]
    this.end = this.selection[1]

  update: (idx, addToRange = false) ->
    {start, end} = this
    newSelection = switch this.selection.length
      when 0 then [idx]
      when 1
        if addToRange
          if start > idx then [idx, start] else if start < idx then [start, idx] else []
        else if idx != start
          [idx]
        else
          []
      when 2
        if addToRange
          if idx < start then [idx, start] else if idx > end then [end, idx] else []
        else
          [idx]

    this.hunk.setState(selection: newSelection)

  contains: (idx) ->
    {start, end} = this
    switch this.selection.length
      when 1 then start == idx
      when 2 then idx >= start and idx <= end
      else false

  isRange: ->
    this.selection.length == 2

  slice: (lines) ->
    if this.end?
      lines.slice(this.start, this.end + 1)
    else
      [lines[this.start]]

lineKey = (line) ->
  "#{line.old_lineno}-#{line.new_lineno}"

###*

  Tag Selector

  @jsx core.DOM

###

$ = require 'jqueryify'
require '../vendor/selectize'
core = require './core'

module.exports = core.createComponent

  onChange: (values) ->
    this.props.onChange?(values.split(','))

  componentDidMount: ->
    $dom = $(this.getDOMNode())
    # XXX: How do free resources and do we need to do that?
    loaded = false
    $dom.selectize
      create: true
      multiple: true
      preload: true
      plugins: ['remove_button']
      delimiter: ','
      load: (query, callback) =>
        return if loaded
        loaded = true
        if this.props.tagsURL
          $.ajax(url: this.props.tagsURL, dataType: 'json')
            .then (tags) =>
              tags = Object.keys(tags).map (t) -> {value: t, text: t}
              callback tags
        else
          callback []
    this.selectize = $dom[0].selectize
    this.selectize.on('change', this.onChange) if this.props.onChange?
    this.selectize.on('item_add', this.props.onItemAdd) if this.props.onItemAdd?
    this.selectize.on('item_remove', this.props.onItemRemove) if this.props.onItemRemove?

  values: ->
    this.selectize.items

  render: ->
    tags = this.getModel() or []
    `<input ref="tags" placeholder="Add tags" value={tags.join(',')} />`

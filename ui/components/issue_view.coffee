###*

  Issues view

  @jsx core.DOM

###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
core = require './core'

module.exports = core.createComponent
  render: ->
    model = this.getModel()
    `<div class="IssueView">
      <h3>{model.name}</h3>
      <p>{model.body}</p>
     </div>`

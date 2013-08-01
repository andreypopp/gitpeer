###*

  Issues view

  @jsx core.DOM

###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
core = require './core'

module.exports = core.createComponent
  render: ->
    `<div class="IssueView">
      <h1>{model.name}</h1>
      <p>{model.body}</p>
     </div>`

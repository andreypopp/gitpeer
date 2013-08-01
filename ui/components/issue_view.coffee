###*

  Issues view

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
{createComponent} = require './core'

module.exports = createComponent
  render: ->
    `<div class="IssueView">
      <h1>{model.name}</h1>
      <p>{model.body}</p>
     </div>`

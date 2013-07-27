###*

  Blob view

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
{createComponent} = require './core.coffee'

BlobView = createComponent
  render: ->
    blob = this.getModel()
    `<div class="BlobView">
      <pre><code>{blob.content}</code></pre>
     </div>`

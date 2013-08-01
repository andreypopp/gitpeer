###*

  Blob view

  @jsx core.DOM

###

core = require './core'

module.exports = core.createComponent
  render: ->
    blob = this.getModel()
    `<div class="BlobView">
      <pre><code>{blob.content}</code></pre>
     </div>`

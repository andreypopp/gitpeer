###*

  Render commit summary in a line

  @jsx core.DOM

###

Timestamp = require 'react-time'
core = require './core'

formatMessage = (message) ->
  [headline, message] = message.split('\n\n')
  if message
    message = message
      .split('\n')
      .filter(Boolean)
      .map (line) -> `<p>{line}</p>`
  {headline, message}

module.exports = core.createComponent

  getInitialState: ->
    showMessage: not this.props.nomessage?

  render: ->
    model = this.getModel()

    {headline, message} = formatMessage(model.message)
    showMessage = message? and (
        not this.props.nomessage? and
        this.state?.showMessage or
        this.state?.showMessage)

    `<a href={model._links.self_html.href} class="CommitLine">
      <div class="head">
        <div class="sha">{model.id.substring(0, 6)}</div>
        <div class="headline">{headline}</div>
        <div class="author">{model.author.name}</div>
        {!this.props.notime &&
          <div class="time">
            authored <Timestamp value={model.author.time} relative />
          </div>}
      </div>
      {showMessage && <div class="message">{message}</div>}
     </a>`

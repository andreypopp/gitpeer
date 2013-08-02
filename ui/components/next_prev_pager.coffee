###*

  Pager with next and prev buttons.

  @jsx core.DOM

###

core = require './core'
Control = require './control'

module.exports = core.createComponent
  render: ->
    {next_html, prev_html} = this.getModel()._links
    {nextIcon, prevIcon, nextLabel, prevLabel} = this.props
    nextIcon = nextIcon or 'arrow-down'
    prevIcon = prevIcon or 'arrow-up'
    next = Control(icon: nextIcon, label: nextLabel, href: next_html.href, class: 'next') if next_html
    prev = Control(icon: prevIcon, label: prevLabel, href: prev_html.href, class: 'prev') if prev_html
    `<div class="Controls NextPrevPager">{next}{prev}</div>`

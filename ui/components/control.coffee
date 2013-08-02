###*

  Issues view

  @jsx core.DOM

###

core = require './core'

module.exports = core.createClass
  render: ->
    iconCls = "icon icon-#{this.props.icon}"
    `<a href={this.props.href} class={this.props.class} onClick={this.props.onClick}>
      <i class={iconCls}></i> {this.props.label}
     </a>`

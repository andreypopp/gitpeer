{Model, Collection} = require 'backbone'
React = require 'react-tools/build/modules/react'
{isString} = require 'underscore'

isObservable = (o) ->
  (o instanceof Collection) or (o instanceof Model)

deserialized = (data) ->
  if isString(data) then JSON.parse(data) else data

Base =

  observe: (o, observers = null) ->
    this._observations = this._observations or []
    observers = unless observers?
      eventNames = if o instanceof Collection
        'add remove reset sort': -> this.forceUpdate()
      else if o instanceof Model
        'change': -> this.forceUpdate()
      else
        throw new Error("#{o} should be a model or a collection")
    this._observations.push(o)
    o.on(observers, this)
    o

  stopObserving: (o) ->
    idx = this._observations.indexOf(o)
    if idx > -1
      o = this._observations[idx]
      this._observations.splice(idx, 1)
      o.off(null, null, this)

  getModel: ->
    deserialized(this.state?.model or this.props?.model)

  componentDidMount: (node) ->
    model = this.getModel()
    this.observe(model) if isObservable model

  componentWillUnmount: ->
    if this._observations?.length > 0
      for o in this._observations
        o.off(null, null, this)

createComponent = (spec) ->
  spec.mixins = (spec.mixins or []).concat [Base]
  React.createClass(spec)

module.exports = {
  createComponent, renderComponent: React.renderComponent,
  deserialized, isObservable}

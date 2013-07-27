{Events} = require 'backbone'
{extend} = require 'underscore'

class Auth
  extend this.prototype, Events

  keyName: 'user'

  constructor: ->
    window.addEventListener 'storage', ({key, newValue}) =>
      user = try
        JSON.parse newValue
      catch
        null
      this.setUser user, false

  setUser: (user, store = true) ->
    if store
      window.localStorage.setItem(this.keyName, JSON.stringify(user))
    this.trigger('user', user)

  user: ->
    try
      JSON.parse window.localStorage.getItem(this.keyName)
    catch
      null

module.exports = new Auth

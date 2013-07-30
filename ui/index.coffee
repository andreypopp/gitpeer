###*
  @jsx React.DOM
###


$ = require 'jqueryify'
{resolve} = require 'kew'
{Router, Model, Collection, history} = require 'backbone'
React = require 'react-tools/build/modules/react'

{renderComponent, createComponent} = require './components/core'
{History, Comment, Contents, Commit, Tree, Blob} = require './models'
CommitView = require './components/commit_view'
ContentsView = require './components/contents_view'
HistoryView = require './components/history_view'
Auth = require './auth'

App = createComponent

  handleClick: (e) ->
    href = if e.nativeEvent.toElement?.tagName == 'A'
      e.nativeEvent.toElement.attributes?.href?.value
    else if e.nativeEvent.toElement?.parentNode?.tagName == 'A'
      e.nativeEvent.toElement.parentNode.attributes?.href?.value
    if href? and (not /^https?:\/\//.exec href) and (not /^\/auth/.exec href)
      e.preventDefault()
      this.router.navigate(href, trigger: true)

  show: (model) ->
    this.setState(model: model)

  fetchAndShow: (model, options) ->
    model.fetch(options).then => this.show(model)

  viewFor: (model) ->
    if model instanceof Contents
      `<ContentsView model={model} />`
    else if model instanceof History
      `<HistoryView model={model} />`
    else if model instanceof Commit
      `<CommitView model={model} />`
    else
      null

  componentDidMount: (node) ->
    this.router = new Router
      routes:
        '': 'contents'
        'contents': 'contents'
        'contents/:ref/*path': 'contents'
        'history': 'history'
        'history/:ref': 'history'
        'commit/:id': 'commit'

    this.router.on 'route:contents', (ref = 'master', path = '/') =>
      this.fetchAndShow new Contents(ref: ref, path: path)

    this.router.on 'route:history', (ref = 'master') =>
      this.fetchAndShow new History(ref: ref)

    this.router.on 'route:commit', (id) =>
      this.fetchAndShow new Commit(id: id)

  render: ->
    model = this.getModel()
    commit = model?.commit
    name = window.__data?.name or 'project'

    `<div class="App" onClick={this.handleClick}>
      <header>
        <a class="name" href="/">{name}</a>
        <div class="nav">
          <a href="/contents">code</a>
          <a href="/history">history</a>
        </div>
      </header>
      <AuthStatus user={this.props.user} />
      {this.viewFor(model)}
     </div>`

AuthStatus = createComponent
  signIn: ->
    window.open('/auth/github')

  signOut: ->
    window.open('/auth/logout')

  render: ->
    if this.props.user
      `<div class="AuthStatus">
        <div class="meta">
          {this.props.user.name}
          <a class="signout" onClick={this.signOut}> (signout)</a>
          <img src={this.props.user.avatar} />
        </div>
      </div>`
    else
      `<div class="AuthStatus">
        <div class="meta">
          <a class="signin" onClick={this.signIn}>sign in with GitHub</a>
        </div>
       </div>`

window.onload = ->
  GitMan = window.GitMan = {}
  GitMan.Auth = Auth
  GitMan.app = renderComponent(App(user: GitMan.Auth.user()), document.body)

  GitMan.Auth.on 'user', (user) ->
    GitMan.app.setProps {user}

  history.start(pushState: true)

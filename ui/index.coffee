###*
  @jsx React.DOM
###


$ = require 'jqueryify'
{resolve} = require 'kew'
{Router, Model, Collection, history} = require 'backbone'
React = require 'react-tools/build/modules/react'

{renderComponent, createComponent} = require './components/core'
{History, Comment, Contents, Commit, Tree, Blob, Issues, Issue} = require './models'
CommitView = require './components/commit_view'
ContentsView = require './components/contents_view'
HistoryView = require './components/history_view'
IssuesView = require './components/issues_view'
IssueView = require './components/issue_view'
IssueEditor = require './components/issue_editor'
Auth = require './auth'

App = createComponent

  show: (model) ->
    this.setState(model: model)

  fetchAndShow: (model, options) ->
    model.fetch(options).then => this.show(model)

  viewFor: (model) ->
    if model instanceof Contents
      ContentsView {model}
    else if model instanceof History
      HistoryView {model}
    else if model instanceof Commit
      CommitView {model}
    else if model instanceof Issues
      IssuesView {model}
    else if model instanceof Issue
      if model.id? then IssueView {model} else IssueEditor {model}
    else
      null

  componentWillUnmount: ->
    $(document).off 'click.route'

  componentDidMount: (node) ->
    $(document).on 'click.route', 'a', (e) =>
      href = if e.currentTarget.tagName == 'A'
        e.currentTarget.attributes?.href?.value
      if href? and (not /^https?:\/\//.exec href) and (not /^\/auth/.exec href)
        e.preventDefault()
        this.props.router.navigate(href, trigger: true)

    this.props.router.on 'route:contents', (ref = 'master', path = '/') =>
      this.fetchAndShow new Contents(ref: ref, path: path)

    this.props.router.on 'route:history', (ref = 'master') =>
      this.fetchAndShow new History(ref: ref)

    this.props.router.on 'route:commit', (id) =>
      this.fetchAndShow new Commit(id: id)

    this.props.router.on 'route:issues', (id) =>
      this.fetchAndShow new Issues()
      
    this.props.router.on 'route:issue', (id) =>
      this.fetchAndShow new Issue(id: id)

    this.props.router.on 'route:issues:new', (id) =>
      this.show new Issue()

  render: ->
    model = this.getModel()
    commit = model?.commit
    name = window.__data?.name or 'project'

    `<div class="App">
      <header>
        <a class="name" href="/">{name}</a>
        <Navigation router={this.props.router} />
      </header>
      <AuthStatus user={this.props.user} />
      {this.viewFor(model)}
     </div>`

Navigation = createComponent
  componentDidMount: ->
    this.props.router.on 'route', => this.forceUpdate()

  render: ->
    _links = {
      contents: {href: '/contents'},
      history: {href: '/history'},
      issues: {href: '/issues'},
    }
    links = for name, link of _links
      `<a href={link.href}>{name}</a>`
    `<div class="Navigation">{links}</div>`

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
  GitMan.router = new Router
    routes:
      '': 'contents'
      'contents': 'contents'
      'contents/:ref/*path': 'contents'
      'history': 'history'
      'history/:ref': 'history'
      'commit/:id': 'commit'
      'issues/new': 'issues:new'
      'issues/:id': 'issue'
      'issues': 'issues'
  GitMan.app = renderComponent(
    App(router: GitMan.router, user: GitMan.Auth.user()),
    document.body)

  GitMan.Auth.on 'user', (user) ->
    GitMan.app.setProps {user}

  history.start(pushState: true)

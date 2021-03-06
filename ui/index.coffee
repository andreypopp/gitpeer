###*
  @jsx core.DOM
###


$ = require 'jqueryify'
{resolve} = require 'kew'
{Router, Model, Collection, history} = require 'backbone'
require 'backbone-query-parameters'

core = require './components/core'
{History, Comment, Contents, Repository,
  Commit, Tree, Blob, Issues, Issue} = require './models'
CommitView = require './components/commit_view'
ContentsView = require './components/contents_view'
HistoryView = require './components/history_view'
IssuesView = require './components/issues_view'
IssueView = require './components/issue_view'
NewIssueView = require './components/new_issue_view'
Auth = require './auth'

App = core.createComponent

  show: (model) ->
    href = model._links?.self_html?.href
    throw new Error("can't show #{model}: no self_html link") unless href
    this.props.router.navigate(href, trigger: true)

  fetchAndShow: (model, options) ->
    model.fetch(options).then => this.setState(model: model)

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
      if model.id? then IssueView {model} else NewIssueView {model}
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

    this.props.router.on 'route:contents', (ref = this.props.repository.ref, path = '/') =>
      this.fetchAndShow new Contents(ref: ref, path: path)

    this.props.router.on 'route:history', (ref = this.props.repository.ref, params = {}) =>
      history = new History(ref: ref, limit: params.limit, after: params.after)
      this.fetchAndShow history

    this.props.router.on 'route:commit', (id) =>
      this.fetchAndShow new Commit(id: id)

    this.props.router.on 'route:issues', (params = {}) =>
      this.fetchAndShow new Issues(state: params.state)

    this.props.router.on 'route:issue', (id) =>
      this.fetchAndShow new Issue(id: id)

    this.props.router.on 'route:issues:new', (id) =>
      this.setState(model: new Issue())

  render: ->
    model = this.getModel()
    commit = model?.commit
    name = this.props.repository.name or 'project'

    `<div class="App">
      <header>
        <a class="name" href="/">{name}</a>
        <Navigation router={this.props.router} repository={this.props.repository} />
      </header>
      <AuthStatus user={this.props.user} />
      {this.viewFor(model)}
     </div>`

Navigation = core.createComponent
  componentDidMount: ->
    this.props.router.on 'route', => this.forceUpdate()

  render: ->
    links = for name, link of this.props.repository._links when link.title?
      `<a href={link.href}>{link.title}</a>`
    `<div class="Navigation">{links}</div>`

AuthStatus = core.createComponent
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

window._ = require 'underscore'
window.Backbone = require 'backbone'

window.onload = ->
  GitPeer = window.GitPeer = {}
  GitPeer.repository = repository = new Repository(__data, parse: true)
  GitPeer.Auth = Auth
  GitPeer.router = new Router
    routes:
      '': 'contents'
      'contents': 'contents'
      'contents/:ref*path': 'contents'
      'history': 'history'
      'history/:ref': 'history'
      'commit/:id': 'commit'
      'issues/new': 'issues:new'
      'issues/:id': 'issue'
      'issues': 'issues'
  GitPeer.app = core.renderComponent(
    App
      router: GitPeer.router
      user: GitPeer.Auth.user()
      repository: repository,
    document.body)

  GitPeer.Auth.on 'user', (user) ->
    GitPeer.app.setProps {user}

  history.start(pushState: true)

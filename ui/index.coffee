###*
  @jsx React.DOM
###


{resolve} = require 'kew'
{Router, Model, Collection, history} = require 'backbone'
React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
uriTemplate = require 'uri-template'

{renderComponent, createComponent} = require './core.coffee'
{History, Comment, Contents, Commit, Tree, Blob} = require './models.coffee'
{CommitStatus, CommitView} = require './commit.coffee'

Date::sameDay = (o) ->
  return false unless o?
  this.getYear() == o.getYear() \
    and this.getMonth() == o.getMonth() \
    and this.getDate() == o.getDate()

TreeContentsView = createComponent
  createEntryView: (entry) ->
    icon = switch entry.type
      when 'tree' then 'icon-folder-close-alt'
      else 'icon-file-alt'
    `<li class="TreeEntry">
      <a href={this.entryURI(entry)}>
        <i class={icon}></i>{entry.name}
      </a>
     </li>`

  entryURI: (entry) ->
    uriTemplate.parse(this.getModel()._links.entry_contents_html.href)
      .expand(path: entry.name)

  render: ->
    model = this.getModel()
    `<div class="TreeContentsView">
      <ul>{model.tree.entries.map(this.createEntryView)}</ul>
     </div>`

BlobView = createComponent
  render: ->
    blob = this.getModel()
    `<div class="BlobView">
      <pre><code>{blob.content}</code></pre>
     </div>`

ContentsView = createComponent
  viewFor: (model) ->
    if model instanceof Tree
      `<TreeContentsView model={this.getModel()} />`
    else if model instanceof Blob
      `<BlobView model={model} />`
    else
      null

  render: ->
    model = this.getModel()
    `<div class="ContentsView">
      <Breadcrumb model={model} />
      {this.viewFor(model.tree || model.blob)}
      <CommitStatus model={model.commit} />
     </div>`

HistoryView = createComponent

  next: ->
    this.getModel().fetchNext()

  prev: ->
    this.getModel().fetchPrev()

  $pager: ->
    model = this.getModel()
    if model.pagination?
      next = if model.pagination.next
        `<a class="next" href={model.urlNext()}>
          <i class="icon-long-arrow-down"></i> older
         </a>`
      prev = if model.pagination.prev
        `<a class="prev" href={model.urlPrev()}>
          <i class="icon-long-arrow-up"></i> newer
         </a>`
      `<div class="pager">{next}{prev}</div>`

  render: ->
    model = this.getModel()
    date = undefined
    elements = []
    commits = for commit in model.commits.models
      unless commit.author.time.sameDay(date)
        elements.push `<div class="date">
            <Timestamp value={commit.author.time} format="%Y/%m/%d" />
          </div>`
      date = commit.author.time
      elements.push `<CommitStatus skipTime model={commit} />`
    `<div class="HistoryView">
      {this.$pager()}
      <div class="commits">{elements}</div>
      {this.$pager()}
     </div>`

Breadcrumb = createComponent

  render: ->
    model = this.getModel()
    parts = if model?.path?
      model.path.split('/').filter(Boolean)
    else
      []

    elems = parts.reduce ((s, cur) ->
      s = s.slice(0)
      prev = s[s.length - 1]
      link = "#{prev.link}/#{cur}"
      s.push
        link: link
        el: `<li><a href={link}>{cur}</a></li>`
      s
    ), [{el: `<li><a href="/">/</a></li>`, link: '/contents/master'}]

    elems = elems.map (e) -> e.el

    `<ul class="Breadcrumb">
      {elems}
     </ul>`

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
      <Auth user={this.props.user} />
      {this.viewFor(model)}
     </div>`

Auth = createComponent
  signIn: ->
    window.open('/auth/github')

  signOut: ->
    window.open('/auth/logout')

  render: ->
    if this.props.user
      `<div class="Auth">
        <div class="meta">
          {this.props.user.name}
          <a class="signout" onClick={this.signOut}> (signout)</a>
          <img src={this.props.user.avatar} />
        </div>
      </div>`
    else
      `<div class="Auth">
        <div class="meta">
          <a class="signin" onClick={this.signIn}>sign in with GitHub</a>
        </div>
       </div>`

class AuthData
  key: 'gitman.user'

  constructor: (onchange) ->
    this.onchange = onchange
    this.user = this.getUser()
    window.addEventListener 'storage', ({key, newValue}) =>
      if key == 'gitman.user'
        this.user = this.getUser()
        this.onchange(this.user)

  getUser: ->
    try
      JSON.parse(window.localStorage.getItem(this.key))
    catch
      null

  setUser: (user) ->
    # TODO: this should drop session as well
    window.localStorage.setItem(this.key, user)
    this.user = user

  signOut: ->
    this.setUser(null)
    this.onchange(this.user)

window.onload = ->
  GitMan = window.GitMan = {}
  GitMan.authData = new AuthData (user) -> GitMan.app.setProps(user: user)
  GitMan.app = renderComponent(App(user: GitMan.authData.user), document.body)
  history.start(pushState: true)

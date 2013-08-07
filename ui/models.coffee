{Model, Collection} = require 'backbone'
Record = require 'backbone.record'
lazyProperty = require 'lazy-property'
{resolve} = require 'kew'

url = (url) ->
  url.replace(/\/+/g, '/')

Collection::fetched = ->
  this.fetch().then => resolve(this)

Model::fetched = ->
  this.fetch().then => resolve(this)

class Record extends Record
  @lazyProperty: (name, func) ->
    lazyProperty(this.prototype, name, func)

class exports.Author extends Record
  @define
    email: null
    name: null
    time: Date

class exports.Commit extends Record
  url: -> url "/api/commit/#{this.id}"

  @define
    message: null,
    author: exports.Author
    commiter: exports.Author
    tree_id: null
    diff: null
    _links: null

  @lazyProperty 'comments', ->
    return undefined
    new exports.Comments([], url: url "/api/comments/#{this.id}")

class exports.Blob extends Record
  @define
    name: null
    content: null
    _links: null

class exports.Entry extends Record
  @define
    name: null
    type: null
    _links: null

class exports.Entries extends Collection
  model: exports.Entry
  comparator: (model) ->
    typeIdx = switch model.type
      when 'tree' then 0
      else 1
    "#{typeIdx}:#{model.name}"

class exports.Tree extends Record
  @define
    entries: exports.Entries
    _links: null

class exports.Contents extends Record
  url: -> url "/api/contents/#{this.ref}/#{this.path}"
  @define
    path: null
    ref: null
    commit: exports.Commit
    tree: exports.Tree
    blob: exports.Blob
    _links: null

class exports.Commits extends Collection
  model: exports.Commit

class exports.History extends Record
  @define
    ref: null
    commits: exports.Commits
    after: null
    limit: null
    _links: null

  url: (pagination = this.pagination) ->
    params = {}
    params.after = this.after if this.after?
    params.limit = this.limit if this.limit?
    query = unless $.isEmptyObject(params) then "?#{$.param(params)}" else ''
    url "/api/history/#{this.ref}#{query}"

class exports.Comment extends Record
  @define
    object_id: null
    content: null
    created: null
    author: exports.Author
    position: null

class exports.Comments extends Collection
  model: exports.Comment

class exports.Issue extends Record
  url: ->
    if this.id then "/api/issues/#{this.id}" else "/api/issues"

  @define
    name: null
    body: null
    created: Date
    updated: Date
    state: null
    tags: null

class exports.IssuesCollection extends Collection
  model: exports.Issue

class exports.Issues extends Record
  url: ->
    params = {}
    params.state = this.state if this.state?
    query = unless $.isEmptyObject(params) then "?#{$.param(params)}" else ''
    url "/api/issues#{query}"

  @define
    issues: exports.IssuesCollection
    state: null
    stats: null
    _links: null

class exports.Repository extends Record
  @define 'name', 'description', 'ref', '_links'

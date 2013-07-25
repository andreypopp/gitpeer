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
    _links: null

  constructor: ->
    this.pagination = {limit: 50}
    super

  url: (pagination = this.pagination) ->
    params = {}
    params.limit = pagination.limit if pagination.limit?
    params.after = pagination.after if pagination.after?
    query = unless $.isEmptyObject(params) then "?#{$.param(params)}" else ''
    url "/api/history/#{this.ref}#{query}"

  parse: (resp, options) ->
    if resp.commits.length == this.pagination.limit
      this.pagination.next =
        limit: this.pagination.limit
        after: resp.commits.pop().id
        prev: this.pagination
    super(resp, options)

  urlNext: ->
    this.url(this.pagination.next)

  urlPrev: ->
    this.url(this.pagination.prev)

  fetchNext: ->
    if this.pagination.next?
      this.pagination = this.pagination.next
      this.fetch()

  fetchPrev: ->
    if this.pagination.prev?
      this.pagination = this.pagination.prev
      this.fetch()

class exports.Comment extends Record
  @define
    object_id: null
    content: null
    created: null
    author: exports.Author
    position: null

class exports.Comments extends Collection
  model: exports.Comment

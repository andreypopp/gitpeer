###*

  Contents view

  @jsx React.DOM

###

React = require 'react-tools/build/modules/react'
Timestamp = require 'react-time'
uriTemplate = require 'uri-template'

BlobView = require './blob_view'
CommitLine = require './commit_line'
{createComponent} = require './core'

DirectoryContentsView = createComponent

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
    `<div class="DirectoryContentsView">
      <ul>{model.tree.entries.map(this.createEntryView)}</ul>
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

module.exports = createComponent
  render: ->
    model = this.getModel()
    contents = if model.tree?
      `<DirectoryContentsView model={model} />`
    else if model.blob?
      `<BlobView model={model.blob} />`
    `<div class="ContentsView">
      <Breadcrumb model={model} />
      {contents}
      <CommitLine nomessage model={model.commit} />
     </div>`

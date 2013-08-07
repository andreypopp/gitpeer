require 'sequel'
require 'scorched'
require 'omniauth'
require 'omniauth-github'
require 'gitpeer'
require 'gitpeer/application'
require 'gitpeer/controller/uri_templates'
require 'gitpeer/auth'
require 'gitpeer/repository'
require 'gitpeer/issues'

class App < GitPeer::Application
  include GitPeer::Controller::URITemplates

  uri :page_root,          '/'
  uri :page_contents,      '/contents/{ref}{+path}'
  uri :page_history,       '/history/{ref}{?limit,after}'
  uri :page_path_history,  '/history/{ref}{+path}{?limit,after}'
  uri :page_commit,        '/commit/{id}'
  uri :page_blob,          '/blob/{id}'
  uri :page_issues,        '/issues{?state}'
  uri :page_issue,         '/issues/{id}'

  db = Sequel.connect('sqlite://.git/gitpeer.db')

  auth = GitPeer::Auth.configure do
    provider :github,
      '0db74a96913fc2b5fb54',
      'fd0a74f0b3fa2f2722b8ba0dae191dcb29be8c7b'
  end

  issues = GitPeer::Issues.configure(db: db) do
    representation GitPeer::Issues::Issue, extend: true do
      link :self_html, template: uri(:page_issue)
    end
 
    representation GitPeer::Issues::Issues, extend: true do
      link :self_html, template: uri(:page_issues)
      link :filtered_html, templated: true do
        "#{uri :page_issues}{?state}"
      end
    end
  end

  git = GitPeer::Repository.configure(repo_path: '.') do

    representation Rugged::Commit, name: :basic, extend: true do
      link :self_html, template: uri(:page_commit)
      link :contents_html do
        uri :page_contents, ref: obj.tree_id
      end
    end

    representation Rugged::Commit, extend: true do
      link :self_html, template: uri(:page_commit)
      link :contents_html do
        uri :page_contents, ref: obj.tree_id
      end
    end

    representation Rugged::Blob, extend: true do
      link :self_html, template: uri(:page_blob)
    end

    representation GitPeer::Repository::Contents, extend: true do
      link :self_html, template: uri(:page_contents)
      link :entry_contents_html, templated: true do
        "#{uri(:page_contents, ref: obj.ref, path: obj.path)}/{+path}"
      end
    end

    representation GitPeer::Repository::History, extend: true do
      link :self_html, template: uri(:page_history)
      link :next_html do
        uri(:page_history, ref: obj.ref, limit: obj.limit, after: obj.next_id) if obj.next_id
      end
      link :prev_html do
        uri(:page_history, ref: obj.ref, limit: obj.limit, after: obj.prev_id) if obj.prev_id
      end
    end

    representation GitPeer::Repository::Repository, extend: true do
      link :self_html,      template: uri(:page_root)
      link :contents_html,  template: uri(:page_contents)
      link :history_html,   template: uri(:page_history)
    end
  end

  mount '/api/issues',  issues
  mount '/api',         git
  mount '/auth',        auth
  mount '/a',           Rack::File.new('ui/assets')

  get uris.keys do
    page(
      title: git.repository.name,
      stylesheets: ['/a/index.css'],
      scripts: ['/a/index.js'],
      data: GitPeer::Repository.new(env).json(git.repository)
    )
  end

  configure!
end

use Rack::Session::Cookie
run App

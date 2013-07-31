require 'sqlite3'
require 'scorched'
require 'omniauth'
require 'omniauth-github'
require 'gitpeer'
require 'gitpeer/auth'
require 'gitpeer/api/repository'
require 'gitpeer/api/issues'

class App < GitPeer::Controller
  uri :page_root,          '/'
  uri :page_contents,      '/contents/{ref}{+path}'
  uri :page_history,       '/history/{ref}{?limit,after}'
  uri :page_path_history,  '/history/{ref}{+path}{?limit,after}'
  uri :page_commit,        '/commit/{id}'
  uri :page_blob,          '/blob/{id}'

  db = SQLite3::Database.new("./.git/gitpeer.db")
  assets = Rack::File.new('ui/assets')

  auth = GitPeer::Auth.configure do
    provider :github,
      '0db74a96913fc2b5fb54',
      'fd0a74f0b3fa2f2722b8ba0dae191dcb29be8c7b'
  end

  issues = GitPeer::API::Issues.configure(db: db)

  git = GitPeer::API::Repository.configure(repo_path: '.') do

    extend_representation Rugged::Commit, name: :basic do
      link :self_html do uri :page_commit, id: represented.oid end
      link :contents_html do
        uri :page_contents, ref: represented.tree_id
      end
    end

    extend_representation Rugged::Commit do
      link :self_html do uri :page_commit, id: represented.oid end
      link :contents_html do
        uri :page_contents, ref: represented.tree_id
      end
    end

    extend_representation Rugged::Blob do
      link :self_html do uri :page_blob, id: represented.oid end
    end

    extend_representation GitPeer::API::Repository::Contents do
      link :self_html do
        uri :page_contents,
          ref: represented.ref,
          path: represented.path
      end
      # XXX: It would be nice to have URITemplate#partial_expand instead
      link :rel => :entry_contents_html, :templated => true do
        prefix = uri :page_contents, ref: represented.ref, path: represented.path
        "#{prefix}/{+path}"
      end
    end

    extend_representation GitPeer::API::Repository::History do
      link :self_html do
        uri :page_history,
          ref: represented.ref,
          limit: represented.limit,
          after: represented.after
      end
    end

    extend_representation GitPeer::API::Repository::Repository do
      link :self_html do
        uri :page_root, ref: represented.default_branch
      end
      link :contents_html do
        uri :page_contents, ref: represented.default_branch
      end
      link :history_html do
        uri :page_history,  ref: represented.default_branch
      end
    end
  end

  mount '/api/issues',  issues
  mount '/api',         git
  mount '/auth',        auth
  mount '/a',           assets

  get '/**' do
    page(
      title: git.repository.name,
      stylesheets: ['/a/index.css'],
      scripts: ['/a/index.js']
    )
  end
end

use Rack::Session::Cookie
run App

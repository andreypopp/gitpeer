require 'gitpeer'
require 'gitpeer/repository'

class App < GitPeer::Controller
  uri :page_root,          '/'
  uri :page_contents,      '/contents/{ref}{/path*}'
  uri :page_history,       '/history/{ref}{?limit,after}'
  uri :page_path_history,  '/history/{ref}{/path*}{?limit,after}'
  uri :page_commit,        '/commit/{id}'
  uri :page_tree,          '/tree/{id}'
  uri :page_blob,          '/blob/{id}'
  uri :page_branch,        '/branch/{id}'
  uri :page_tag,           '/tag/{id}'
  uri :page_object,        '/{id}'

  assets = Rack::Directory.new('ui/assets')
  git = GitPeer::Repository.configure(repo_path: '.')

  git.extend_representation_for GitPeer::Repository::Repository do
    link :contents_html do
      uri :page_contents, ref: represented.default_branch
    end
  end

  mount '/api', git
  mount '/a',   assets
end

run App

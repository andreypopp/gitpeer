require 'gitpeer'
require 'gitpeer/repository'

class App < GitPeer::Controller
  uri :root,          '/'
  uri :contents,      '/contents/{ref}{/path*}'
  uri :history,       '/history/{ref}{?limit,after}'
  uri :path_history,  '/history/{ref}{/path*}{?limit,after}'
  uri :commit,        '/commit/{id}'
  uri :tree,          '/tree/{id}'
  uri :blob,          '/blob/{id}'
  uri :branch,        '/branch/{id}'
  uri :tag,           '/tag/{id}'
  uri :object,        '/{id}'

  @@api     = GitPeer::Repository.configure(repo_path: '.')
  @@assets  = Rack::Directory.new('ui/assets')

  mount '/api', @@api
  mount '/a',   @@assets
end

run App

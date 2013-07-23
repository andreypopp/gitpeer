require 'gitpeer'
require 'gitpeer/repository'

map '/api' do
  run GitPeer::Repository.configure(repo_path: '.')
end
map '/a'   do run Rack::Directory.new('ui/assets') end

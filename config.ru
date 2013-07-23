require 'rugged'
require 'gitpeer'
require 'gitpeer/git'

repo = Rugged::Repository.new('.git')

app = GitPeer::Controller.configure do
  # XXX: we should set this on outer controller because of
  # https://github.com/Wardrop/Scorched/issues/15
  config[:strip_trailing_slash] = :ignore

  mount '/api/git',       GitPeer::Git.configure(repo: repo, name: 'GitPeer')
  mount '/api/comments',  GitPeer::Comments
  mount '/api/wiki',      GitPeer::Wiki
  mount '/api/issues',    GitPeer::Issues
end

map '/a' do
  run Rack::Directory.new('ui/assets')
end

run app

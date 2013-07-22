require 'rugged'
require 'gitpeer'

repo = Rugged::Repository.new('.git')

app = GitPeer::Controller.configure do
  mount '/api/git',       GitPeer::Git.configure(repo: repo)
  mount '/api/comments',  GitPeer::Comments
  mount '/api/wiki',      GitPeer::Wiki
  mount '/api/issues',    GitPeer::Issues
end

run app

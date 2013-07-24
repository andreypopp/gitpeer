require 'scorched'
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

  assets = Rack::Directory.new('ui/assets')
  git = GitPeer::Repository.configure(repo_path: '.')

  git.extend_representation_for Rugged::Commit do
    link :self_html do uri :page_commit, id: represented.oid end
    link :tree_html do uri :page_tree, id: represented.tree_id end
  end

  git.extend_representation_for Rugged::Tree do
    link :self_html do uri :page_tree, id: represented.oid end
  end

  git.extend_representation_for Rugged::Blob do
    link :self_html do uri :page_blob, id: represented.oid end
  end

  git.extend_representation_for GitPeer::Repository::Contents do
    link :self_html do
      uri :page_contents, ref: represented.ref
    end
  end

  git.extend_representation_for GitPeer::Repository::History do
    link :self_html do
      uri :page_history,
        ref: represented.ref,
        limit: represented.limit,
        after: represented.after
    end
  end

  git.extend_representation_for GitPeer::Repository::Repository do
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

  mount       '/api',   git
  mount_rack  '/a',     assets
end

run App

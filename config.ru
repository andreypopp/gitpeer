require 'scorched'
require 'gitpeer'
require 'gitpeer/repository'

class Rack::Page < Rack::File
  def _call(env)
    unless ALLOWED_VERBS.include? env["REQUEST_METHOD"]
      return fail(405, "Method Not Allowed")
    end

    @path = @root

    available = begin
      File.file?(@path) && File.readable?(@path)
    rescue SystemCallError
      false
    end

    if available
      serving(env)
    else
      fail(404, "File not found: #{path_info}")
    end
  end
end

class App < GitPeer::Controller
  uri :page_root,          '/'
  uri :page_contents,      '/contents/{ref}{/path*}'
  uri :page_history,       '/history/{ref}{?limit,after}'
  uri :page_path_history,  '/history/{ref}{/path*}{?limit,after}'
  uri :page_commit,        '/commit/{id}'
  uri :page_tree,          '/tree/{id}'
  uri :page_blob,          '/blob/{id}'

  page = Rack::Page.new('ui/index.html')
  assets = Rack::File.new('ui/assets')
  git = GitPeer::Repository.configure(repo_path: '.')

  git::TreeEntryRepresentation.class_eval do
    link :contents_html do uri :page_contents end
  end

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
  mount_rack            page
end

run App

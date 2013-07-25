require 'scorched'
require 'gitpeer'
require 'gitpeer/api/repository'

class App < GitPeer::Controller
  uri :page_root,          '/'
  uri :page_contents,      '/contents/{ref}{+path}'
  uri :page_history,       '/history/{ref}{?limit,after}'
  uri :page_path_history,  '/history/{ref}{+path}{?limit,after}'
  uri :page_commit,        '/commit/{id}'
  uri :page_blob,          '/blob/{id}'

  assets = Rack::File.new('ui/assets')
  git = GitPeer::API::Repository.configure(repo_path: '.')

  git.extend_representation_for Rugged::Commit, name: :basic do
    link :self_html do uri :page_commit, id: represented.oid end
    link :contents_html do
      uri :page_contents, ref: represented.tree_id
    end
  end

  git.extend_representation_for Rugged::Commit do
    link :self_html do uri :page_commit, id: represented.oid end
    link :contents_html do
      uri :page_contents, ref: represented.tree_id
    end
  end

  git.extend_representation_for Rugged::Blob do
    link :self_html do uri :page_blob, id: represented.oid end
  end

  git.extend_representation_for GitPeer::API::Repository::Contents do
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

  git.extend_representation_for GitPeer::API::Repository::History do
    link :self_html do
      uri :page_history,
        ref: represented.ref,
        limit: represented.limit,
        after: represented.after
    end
  end

  git.extend_representation_for GitPeer::API::Repository::Repository do
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

  get '/**' do
    page(
      stylesheets: [
        '/a/font-awesome/css/font-awesome.css',
        '/a/index.css',
      ],
      scripts: [
        '/a/jquery.js',
        '/a/jquery.autosize.js',
        '/a/index.js',
      ],
      title: 'Project')
  end

end

run App

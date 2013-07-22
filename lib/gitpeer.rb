require 'uri_template'
require 'roar/representer/json'
require 'roar/representer/feature/hypermedia'
require 'rugged'

require 'gitpeer/version'
require 'gitpeer/controller'

module GitPeer

  class Git < Controller
    uri :branch,    '/branch/{id}'
    uri :tag,       '/tag/{id}'
    uri :commit,    '/commit/{id}'
    uri :tree,      '/tree/{id}'
    uri :blob,      '/blob/{id}'
    uri :object,    '/{id}'

    get '/' do
      'git'
    end
    get :branch
    get :tag
    get :commit do
      commit = or_404 { repo.lookup(captures[:id]) }
      not_found unless commit.type == :commit
      commit.extend(CommitRepresenter).to_json
    end
    get :tree
    get :blob
    get :object

    def or_404
      result = begin
        yield
      rescue Rugged::OdbError
        nil
      rescue Rugged::InvalidError
        nil
      rescue Rugged::ObjectError
        nil
      end
      not_found if result == nil
      result
    end

    module CommitRepresenter
      include Roar::Representer::JSON
      include Roar::Representer::Feature::Hypermedia

      property :message
      property :author
    end
  end

  class Code < Controller
    uri :contents,  '/contents/{ref}{/path*}'
    uri :history,   '/history/{ref}{?limit,after}'

    get :contents
    get :history
  end

  class Comments < Controller

    uri :comments,  '/{oid}{?limit,after}'
    uri :comment,   '/{oid}/{cid}'

    get :comments
    post :comments
    get :comment
    put :comment
    delete :comment
  end

  class Wiki < Controller
    uri :wiki_history,  '/history{?limit,after}'
    uri :page_history,  '/history/{pid}{?limit,after}'
    uri :page,          '/page/{pid}'

    get :wiki_history
    get :page_history
    get :page
    put :page
    delete :page
  end

  class Issues < Controller
    uri :issues,    '/{?limit,after}'
    uri :issue,     '/{id}'

    get :issues
    post :issues
    get :issue
    put :issue
    delete :issue
  end
end

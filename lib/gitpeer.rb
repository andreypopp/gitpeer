require 'uri_template'
require 'representable/json/hash'
require 'roar/representer/json'
require 'roar/representer/feature/hypermedia'
require 'rugged'

require 'gitpeer/version'
require 'gitpeer/controller'

module GitPeer

  module GitController
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
  end

  module JSONController
    def json(obj, with: nil)
      if with
        _self = self
        helpers = Module.new do
          define_method :uri do |name, **vars|
            _self.uri(name, **vars)
          end
        end
        obj.extend(with).extend(helpers).to_json
      else
        obj.to_json
      end
    end
  end

  class Git < Controller
    include GitController
    include JSONController

    uri :branch,    '/branch/{id}'
    uri :tag,       '/tag/{id}'
    uri :commit,    '/commit/{id}'
    uri :commit,    '/commit/{id}'
    uri :tree,      '/tree/{id}'
    uri :blob,      '/blob/{id}'
    uri :object,    '/{id}'

    [:branch, :tag, :commit, :tree, :blob, :object].each do |type|
      get type do
        obj = or_404 { repo.lookup(captures[:id]) }
        not_found unless type == :object or obj.type == type
        json obj, with: representer_for(obj.type)
      end
    end

    module CommitRepresenter
      include Roar::Representer::JSON
      include Roar::Representer::Feature::Hypermedia

      property :oid, as: :id
      property :message
      property :author
      property :committer
      property :tree_id
      link :self do uri :commit, id: oid end
      link :tree do uri :tree, id: tree_id end
    end

    module TreeEntryRepresenter
      include Representable::JSON::Hash
      include Roar::Representer::Feature::Hypermedia
    end

    module TreeRepresenter
      include Roar::Representer::JSON
      include Roar::Representer::Feature::Hypermedia

      property :oid, as: :id
      collection :entries, extend: TreeEntryRepresenter
      link :self do
        uri :tree, id: oid
      end
    end

    protected

      def representer_for(type)
        case type
        when :commit
          CommitRepresenter
        when :tree
          TreeRepresenter
        else
          raise "don't know how to represent #{type}"
        end
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

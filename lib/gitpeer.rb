require 'scorched'
require 'uri_template'

require 'gitpeer/version'

module GitPeer

  class API < Scorched::Controller
    include Scorched::Options('uri_templates')

    def uri(name, **vars)
      template = uri_templates[name]
      url template.expand(vars)
    end

    class << self

      def uri(name, template)
        unless template.is_a? URITemplate
          template = URITemplate.new(template)
        end
        uri_templates << { name => template }
      end

      private
        def compile(pattern, match_to_end = false)
          pattern = uri_templates[pattern] || pattern
          if pattern.is_a? URITemplate then
            pattern
          else
            super(pattern, match_to_end)
          end
        end
    end
  end

  class Git < API
    uri :branch,    '/branch/{id}'
    uri :tag,       '/tag/{id}'
    uri :commit,    '/commit/{id}'
    uri :tree,      '/tree/{id}'
    uri :blob,      '/blob/{id}'
    uri :object,    '/{id}'

    get :branch
    get :tag
    get :commit
    get :tree
    get :blob
    get :object
  end

  class Code < API
    uri :contents,  '/contents/{ref}{/path*}'
    uri :history,   '/history/{ref}{?limit,after}'

    get :contents
    get :history
  end

  class Comments < API

    uri :comments,  '/{oid}{?limit,after}'
    uri :comment,   '/{oid}/{cid}'

    get :comments
    post :comments
    get :comment
    put :comment
    delete :comment
  end

  class Wiki < API
    uri :wiki_history,  '/history{?limit,after}'
    uri :page_history,  '/history/{pid}{?limit,after}'
    uri :page,          '/page/{pid}'

    get :wiki_history
    get :page_history
    get :page
    put :page
    delete :page
  end

  class Issues < API
    uri :issues,    '/{?limit,after}'
    uri :issue,     '/{id}'

    get :issues
    post :issues
    get :issue
    put :issue
    delete :issue
  end
end

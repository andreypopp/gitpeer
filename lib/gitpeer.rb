require 'scorched'
require 'uri_template'
require 'roar/representer/json'
require 'roar/representer/feature/hypermedia'
require 'rugged'

require 'gitpeer/version'

module GitPeer

  class API < Scorched::Controller
    include Scorched::Options('uri_templates')

    def uri(name, **vars)
      template = uri_templates[name]
      url template.expand(vars)
    end

    def captures
      return @_captures if @_captures
      pattern = request.breadcrumb.last.mapping[:pattern]
      @_captures = if pattern.is_a? URITemplate
        Hash[pattern.variables.map{|v| v.to_sym}.zip(request.captures)]
      else
        request.captures
      end
      @_captures
    end

    def not_found
      halt 404
    end

    class << self

      def configure(**options, &block)
        p_mappings = @mappings
        p_filters = @filters

        Class::new(self) do
          @mappings = p_mappings
          @filters = p_filters
          options.each_pair do |k, v|
            define_method k.to_sym do
              v
            end
          end
          class_eval(&block) if block_given?
        end
      end

      def mount(prefix, controller)
        self << {pattern: prefix, target: controller}
        controller.config[:auto_pass] = true if controller < Scorched::Controller
      end

      def uri(name, template)
        template = URITemplate.new(template) unless template.is_a? URITemplate
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

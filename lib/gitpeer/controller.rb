require 'scorched'
require 'roar/decorator'
require 'roar/representer/json'
require 'roar/representer/feature/hypermedia'

class GitPeer::Controller < Scorched::Controller
  include Scorched::Options('uri_templates')

  def uri(name, **vars)
    paths =  request.breadcrumb[0..-2].map { |x| x[:path] }
    template = uri_templates[name]
    url "#{paths.join}#{template.expand(vars)}"
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
      # Save mappigns and filters so we can copy them onto configured controller
      # instance
      # TODO: maybe we should just dup entire class before?
      p_mappings = @mappings
      p_filters = @filters

      Class::new(self) do
        @mappings = p_mappings.clone if p_mappings
        @filters = p_filters.clone if p_filters
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

  module JSONRepresentation
    class Representation < Roar::Decorator
      include Roar::Representer::JSON
      include Roar::Representer::Feature::Hypermedia

      def self.hash_property(name, as: nil)
        property name, as: as, getter: lambda { |*| self[name] }
      end

      def to_hash(options={})
        @options = options
        super(options)
      end

      def uri(name, **vars)
        @options[:controller].uri(name, **vars)
      end
    end

    def json(obj, with: nil)
      if with
        _self = self
        helpers = Module.new do
          define_method :uri do |name, **vars|
            _self.uri(name, **vars)
          end
        end
        with.new(obj).to_json(controller: self)
      else
        obj.to_json
      end
    end
  end

end

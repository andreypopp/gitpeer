require 'scorched'

class GitPeer::Controller < Scorched::Controller
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
end

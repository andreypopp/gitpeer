require 'json'
require 'uri_template'
require 'scorched'

class GitPeer::Controller < Scorched::Controller
  include Scorched::Options('uri_templates')

  config[:strip_trailing_slash] = :ignore

  ##
  # Generate URI out of the template
  #
  def uri(name, **vars)
    paths =  @breadcrumb[0..-1].map { |x| x[:path] }
    template = uri_templates[name] or URITemplate.new(name)
    url "#{paths.join}#{template.expand(vars)}"
  end

  ##
  # Shortcut for request.captures which normalizes some difference
  #
  def captures
    return @_captures if @_captures
    pattern = request.breadcrumb.last.mapping[:pattern]
    @_captures = if pattern.is_a? URITemplate
      Hash[pattern.variables.map{|v| v.to_sym}.zip(request.captures)]
    else
      request.captures
    end
    request.GET.each_pair do |k, v|
      k = k.to_sym
      @_captures[k] = v unless @_captures[k] != nil
    end
    @_captures
  end

  ##
  # Shortcut for getting a param out of captures which also can perform
  # validation and assign a default value
  #
  def param(name, type: nil, default: nil)
    v = captures[name]
    if v
      begin
        v = Integer(v) if type == Integer
        v = Float(v) if type == Float
        v = Date.parse(v) if type == Date
        v = DateTime.parse(v) if type == DateTime
      rescue ArgumentError
        halt 400
      end
    end
    v = default if v == nil
    v
  end

  ##
  # Shortcut for halt 404
  #
  def not_found
    halt 404
  end

  def action
    # we save current requests' breadcrumb in a variable
    @breadcrumb = request.breadcrumb.clone
    super()
  end

  class << self

    attr_accessor :parent

    def mounted(controller); end

    ##
    # Configure controller with class methods or by passing a block
    #
    def configure(**options, &block)
      # save class state over to configured subclass
      copy_over = instance_variables.map do |n|
        v = instance_variable_get(n)
        # Scorched::Options and Scorched::Collection are "inheritable" so we
        # may not bother copying them onto configured subclass
        [n, v] unless v.is_a? Scorched::Options or v.is_a? Scorched::Collection
      end
      copy_over = Hash[copy_over.compact]

      Class::new(self) do
        copy_over.each_pair do |n, v|
          instance_variable_set(n, v)
        end
        config << options
        class_eval(&block) if block_given?
      end
    end

    ##
    # Mount another controller under prefix
    #
    def mount(prefix, controller)
      if controller.is_a? Class and controller < GitPeer::Controller
        controller.config[:auto_pass] = true
        controller.mounted(self) if controller.respond_to? :mounted
        controller.parent = self if controller.respond_to? :parent=
      end
      self << {pattern: prefix, target: controller}
    end

    ##
    # Define named URI template for the controller
    #
    def uri(name, template)
      template = URITemplate.new(template) unless template.is_a? URITemplate
      uri_templates << { name => template }
    end

    protected
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

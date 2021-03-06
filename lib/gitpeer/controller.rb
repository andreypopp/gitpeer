require 'scorched'
require 'gitpeer/application'
require 'gitpeer/context'

class GitPeer::Controller < Scorched::Controller
  require 'gitpeer/controller/uri_templates'
  require 'gitpeer/controller/json_representation'

  include GitPeer::Context::Configurable
  include GitPeer::Controller::URITemplates
  include GitPeer::Controller::JSONRepresentation

  config[:strip_trailing_slash] = :ignore

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

  class << self

    attr_accessor :parent
    attr_accessor :prefix

    def mounted(controller); end

    def configured; end

    def app
      @app ||= lineage.last
    end

    def mounted_at
      @mounted_at ||= lineage
        .reverse
        .map { |p| p.prefix or '' }
        .join
        .gsub(/\/+/, '/')
    end

    def lineage
      current = self
      chain = [current]
      until current == Scorched::Controller or current < GitPeer::Application
        current = self.parent
        chain << current
      end
      chain
    end

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

      controller = Class::new(self) do
        copy_over.each_pair do |n, v|
          instance_variable_set(n, v)
        end
        config << options
        class_eval(&block) if block_given?
      end
      controller.configured
      controller
    end

    ##
    # Mount another controller under prefix
    #
    def mount(prefix, controller)
      if controller.is_a? Class and controller < GitPeer::Controller
        controller.config[:auto_pass] = true
        controller.mounted(self)
        controller.parent = self
        controller.prefix = prefix
        inject controller if controller < GitPeer::Context::Configurable
      end
      self << {pattern: prefix, target: controller}
    end
  end
end

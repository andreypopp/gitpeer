require 'set'
require 'json'

class GitPeer::Representation

  attr_reader :obj, :context

  def initialize(obj, **context)
    @obj = obj
    @context = context
  end

  def to_hash
    result = {}

    props = self.class.all_props
    links = self.class.all_links

    props_seen = Set.new
    links_seen = Set.new

    props.each do |prop|
      name = prop[:name].to_sym
      next if props_seen.include? name
      props_seen << name
      result[name] = represent_prop(name, prop)
    end

    unless links.empty?
      result_links = {}
      links.each do |link|
        name = link[:name]

        next if links_seen.include? name
        links_seen << name

        href = represent_link(name, link)

        result_links[name] = link
          .reject { |k, v| [:proc, :name].include? k }
          .merge(href: href)
      end
      result[:_links] = result_links
    end

    result
  end

  def to_json
    to_hash.to_json
  end

  protected
    def represent_link(name, link)
      if link[:proc]
        instance_eval &link[:proc]
      elsif link[:href]
        link[:href]
      else
        raise RepresentationError.new("cannot generate link #{name} for #{obj}")
      end
    end

    def represent_prop(name, prop)
      is_collection = prop[:collection]

      value = if prop[:from]
        if Proc === prop[:from]
          instance_eval &prop[:from]
        elsif @obj.respond_to? prop[:from]
          @obj.send prop[:from]
        else
          raise RepresentationError.new("#{@obj} doesn't provide #{name} reader")
        end
      elsif @obj.respond_to? name
        @obj.send name
      else
        raise RepresentationError.new("#{@obj} doesn't provide #{name} reader")
      end

      value = value.to_a if is_collection
      if prop[:repr]
        if is_collection
          value = value.map { |e| prop[:repr].new(e, **@context).to_hash }
        else
          value = prop[:repr].new(value, **@context).to_hash
        end
      end
      value
    end

  class << self
    attr_reader :props, :links, :boundary

    def inherited(subclass)
      subclass.class_eval do
        @props = []
        @links = []
        @boundary = false
      end
    end

    def collection(name, **options, &block)
      self.prop(name, **options.merge(collection: true), &block)
    end

    def prop(name, **options, &block)
      if block_given?
        # we inject special "boundary" representation which prevents
        # former variable declarations to have an effect on inline
        # representation
        options[:repr] = Class.new(self) { @boundary = true }
        options[:repr] = Class.new(options[:repr], &block)
      end
      self.props << options.merge(name: name)
    end

    def link(name, **options, &block)
      self.links << options.merge(name: name, proc: block)
    end

    def all_props
      lineage.map { |c| c.props }.flatten(1)
    end

    def all_links
      lineage.map { |c| c.links }.flatten(1)
    end

    def lineage
      current = self
      chain = [current]
      until current.superclass == GitPeer::Representation or current.boundary
        current = self.superclass
        chain << current
      end
      chain
    end

    def for_struct(cls, &block)
      Class.new(self) do
        class_eval(&block) if block_given?
        cls.members.each do |m|
          prop m
        end
      end
    end
  end

  class RepresentationError < Exception; end
end

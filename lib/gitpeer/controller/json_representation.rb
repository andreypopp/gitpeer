require 'json'
require 'roar/decorator'
require 'roar/representer/json'
require 'roar/representer/json/hal'
require 'gitpeer/registry'

module GitPeer::Controller::JSONRepresentation

  class Representation < Roar::Decorator
    include Roar::Representer::JSON
    include Roar::Representer::JSON::HAL

    def to_hash(options={})
      @options = options
      super(options)
    end

    def uri(name, **vars)
      @options[:controller].uri(name, **vars)
    end

    class << self
      def property(name, **options, &block)
        if options[:resolve] and not options[:extend]
          options[:extend] = lambda do |o, **local_options|
            local_options[:controller].representation(o.class, name: options[:name])
          end
        end
        super name, **options, &block
      end

      def value(name, **options, &block)
        options[:getter] = lambda { |*| self[name] }
        property name, **options, &block
      end

      def collection(name, **options, &block)
        if options[:resolve] and not options[:extend]
          options[:extend] = lambda do |o, **local_options|
            local_options[:controller].representation(o.class, name: options[:name])
          end
        end
        super name, **options, &block
      end

      def value_collection(name, **options, &block)
        options[:getter] = lambda { |*| self[name] }
        collection name, **options, &block
      end
    end
  end

  def self.included(controller)
    controller.extend(ClassMethods)
  end

  module ClassMethods
    def representations
      return @representations if @representations
      @representations = GitPeer::Registry.new()
      @representations
    end

    def register_representation(cls, representation = nil, name: nil, override: false, &block)
      unless representation or block_given?
        raise ArgumentError, 'provide a representation'
      end
      unless representation
        representation = Class::new(Representation, &block)
      end
      representations.register(representation, cls, name: name, override: override)
    end

    def get_representation(cls, name: nil, raise_on_missing: true)
      now = self
      while now do
        unless now.respond_to? :representations
          now = now.superclass
          next
        end
        representation = now.representations.query(cls, name: name)
        return representation if representation
        now = now.superclass
      end
      raise GitPeer::Registry::LookupError, cls if raise_on_missing
    end

    def extend_representation(cls, name: nil, &block)
      representation = representation(cls, name: name)
      raise ArgumentError, "representation for #{cls} not found" unless representation
      register_representation(cls, Class::new(representation, &block), name: name, override: true)
    end

    def representation(cls, representation = nil, name: nil, &block)
      if block_given? or representation
        register_representation(cls, representation, name: name, &block)
      else
        get_representation(cls, name: name)
      end
    end

  end

  def body_as(cls)
    representation(cls).new(cls.new).from_json(request.body.read)
  end

  def body
    JSON.parse request.body.read, symbolize_names: true
  end

  def json(obj, with: nil)
    response['Content-Type'] = 'application/json'
    with = get_representation(obj.class, raise_on_missing: false) unless with
    if with
      with.new(obj).to_json(controller: self)
    else
      obj.to_json
    end
  end
end

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
          options[:extend] = lambda do |o, **options|
            options[:controller].representation_for(o.class)
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
          options[:extend] = lambda do |o, **options|
            options[:controller].representation_for(o.class)
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

    def extend_representation_for(cls, name: nil, &block)
      representation = representation_for(cls, name: name)
      raise ArgumentError, "representation for #{cls} not found" unless representation
      register_representation(cls, Class::new(representation, &block), name: name, override: true)
    end

    def representation_for(cls, name: nil, raise_on_missing: true)
      now = self
      while now do
        continue unless now.respond_to? :representations
        representation = now.representations.query(cls, name: name)
        return representation if representation
        now = now.superclass
      end
      raise GitPeer::Registry::LookupError, cls if raise_on_missing
    end

  end

  def json(obj, with: nil)
    response['Content-Type'] = 'application/json'
    with = representation_for(obj.class, raise_on_missing: false) unless with
    if with
      with.new(obj).to_json(controller: self)
    else
      obj.to_json
    end
  end
end

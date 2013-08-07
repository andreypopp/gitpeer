require 'json'
require 'gitpeer/representation'
require 'gitpeer/registry'

module GitPeer::Controller::JSONRepresentation

  class Representation < GitPeer::Representation

    def controller
      @context[:controller]
    end

    def uri(name, **vars)
      controller.uri(name, **vars)
    end

    def self.uri(name)
      proc { controller.uri_template(name) }
    end

    protected

      def representer_for(name, value, prop)
        repr = prop[:repr]
        if repr and not repr < GitPeer::Representation
          repr = controller.representation(repr, name: prop[:repr_name]) 
        end
        repr
      end
  end

  def self.included(controller)
    controller.extend(ClassMethods)
  end

  module ClassMethods
    def representations
      @representations ||= GitPeer::Registry.new()
    end

    def register_representation(cls, repr = nil, name: nil, override: false, &block)
      raise ArgumentError, 'provide a representation' unless repr or block_given?
      repr = Class::new(Representation, &block) unless repr
      representations.register(repr, cls, name: name, override: override)
    end

    def get_representation(cls, name: nil, raise_on_missing: true)
      now = self
      until now == GitPeer::Controller do
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
      repr = representation(cls, name: name)
      raise ArgumentError, "representation for #{cls} not found" unless repr
      register_representation(cls, Class::new(repr, &block), name: name, override: true)
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
      with.new(obj, controller: self).to_json
    else
      obj.to_json
    end
  end
end

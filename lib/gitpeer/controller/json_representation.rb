require 'json'
require 'scorched/collection'
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
      proc { controller.app.all_uri_templates[name] }
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

  def body_as(cls)
    representation(cls).new(cls.new).from_json(request.body.read)
  end

  def body
    JSON.parse request.body.read, symbolize_names: true
  end

  def json(obj, with: nil)
    response['Content-Type'] = 'application/json'
    with = representation(obj.class) unless with
    if with
      with.new(obj, controller: self).to_json
    else
      obj.to_json
    end
  end

  def self.included(controller)
    controller.extend ClassMethods
  end

  module ClassMethods

    def register_representation(cls, repr = nil, name: nil, extend: false, &block)
      declare :representation, 
        cls: cls, repr: repr, name: name, extend: extend, block: block
    end

    def representation(cls, representation = nil, name: nil, extend: false, &block)
      if block_given? or representation
        register_representation(cls, representation, name: name, extend: extend, &block)
      else
        app.all_representations.query(cls, name: name)
      end
    end
  end
end

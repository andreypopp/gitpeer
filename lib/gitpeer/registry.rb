class GitPeer::Registry

  def initialize
    @registrations = {}
  end

  def register(component, interface, name: nil, override: false)
    components = (@registrations[interface] ||= {})
    if not override and components.key? name
      raise ConflictError, 'component already registered'
    end
    components[name] = component
  end

  def query(interface, name: nil)
    while interface do
      component = @registrations.fetch(interface, {})[name]
      return component if component
      interface = interface.superclass
    end
  end

  def get(interface, name: nil)
    component = query(interface, name: name)
    raise LookupError, interface, name if component == nil
    component
  end

  class ConflictError < ArgumentError; end
  class LookupError < KeyError; end
end

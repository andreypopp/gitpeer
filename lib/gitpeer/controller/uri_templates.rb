require 'uri_template'

module GitPeer::Controller::URITemplates

  ##
  # Generate URI out of the template
  #
  def uri(name, **vars)
    template = if name.is_a? Symbol
      construct_uri(name, **vars)
    else
      URITemplate.new(name).expand(vars)
    end
    raise ArgumentError, "unknown URI template #{name}" unless template
    template
  end
  
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.class_eval do
      include Scorched::Options('uri_templates')
    end
  end

  module ClassMethods

    def uri(name, template)
      template = URITemplate.new(template) unless template.is_a? URITemplate
      uri_templates << { name => template }
    end

    def construct_uri(name, **vars)
      template = uri_templates[name]
      if template
        "#{mounted_prefix || ''}#{template.expand(vars)}"
      elsif parent
        parent.construct_uri(name, **vars)
      end
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

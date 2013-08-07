require 'uri_template'

module GitPeer::Controller::URITemplates

  ##
  # Generate URI out of the template
  #
  def uri(name, **vars)
    if name.is_a? Symbol
      app.all_uri_templates[name].expand(vars)
    else
      URITemplate.new(name).expand(vars)
    end
  end

  def self.included(controller)
    controller.extend(ClassMethods)
    controller.class_eval do
      include Scorched::Options :uris
    end
  end

  module ClassMethods

    def uri(name, template)
      template = URITemplate.new(template) unless template.is_a? URITemplate
      uris[name] = template
      declare :uri_template, name: name, template: template
    end

    protected

      def compile(pattern, match_to_end = false)
        pattern = uris[pattern] || pattern
        (pattern.is_a? URITemplate) ? pattern : super(pattern, match_to_end)
      end

  end
end

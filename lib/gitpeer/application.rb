require 'scorched/options'
require 'gitpeer/controller'
require 'gitpeer/controller/json_representation'
require 'gitpeer/registry'
require 'gitpeer/context'

class GitPeer::Application < GitPeer::Controller
  include GitPeer::Context

  def page(title: 'Unnamed Page',
            scripts: [],
            stylesheets: [],
            data: nil)
    response['Content-Type'] = 'text/html'
    stylesheets = stylesheets
      .map { |href| "<link rel='stylesheet' href='#{href}' />" }
    scripts = scripts
      .map { |href| "<script src='#{href}'></script>" }

    if data
      data = data.to_json unless data.is_a? String
      scripts << "<script>var __data = #{data};</script>"
    end

    "<!doctype>
      <title>#{title}</title>
      #{stylesheets.join}
      #{scripts.join}"
  end

  class << self

    def all_representations
      @all_representations ||= GitPeer::Registry.new()
    end

    def all_uri_templates
      @all_uri_templates ||= {}
    end

    def process_representation(decl, controller)
      if decl[:extend]
        repr = all_representations.query(decl[:cls], name: decl[:name])
        repr.class_eval &decl[:block] if decl[:block]
      else
        repr = decl[:repr] || Class.new(GitPeer::Controller::JSONRepresentation::Representation)
        repr.class_eval &decl[:block] if decl[:block]
        all_representations.register(repr, decl[:cls], name: decl[:name])
      end
    end

    def process_uri_template(decl, controller)
      template = "#{controller.mounted_at}/#{decl[:template]}".gsub(/\/+/, '/')
      all_uri_templates[decl[:name]] = URITemplate.new(template)
    end
  end
end

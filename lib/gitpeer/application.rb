require 'gitpeer/controller'

class GitPeer::Application < GitPeer::Controller

  def self.page(title: 'Unnamed Page',
            scripts: [],
            stylesheets: [],
            data: nil)
    stylesheets = stylesheets
      .map { |href| "<link rel='stylesheet' href='#{href}' />" }
      .join
    scripts = scripts
      .map { |href| "<script src='#{href}'></script>" }
      .join

    if data
      data = data.to_json unless data.is_a? String
      scripts << "
        <script>
          var __data = #{data};
        </script>"
    end

    "
    <!doctype>
    <title>#{title}</title>
    #{stylesheets}
    #{scripts}
    ".strip
  end
end

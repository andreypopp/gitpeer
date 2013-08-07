require 'gitpeer/controller'

class GitPeer::Application < GitPeer::Controller

  def page(title: 'Unnamed Page',
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
      scripts << "
        <script>
          var __data = #{json(data)};
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

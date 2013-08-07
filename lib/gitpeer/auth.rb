require 'gitpeer/controller'
require 'gitpeer/controller/uri_templates'

class GitPeer::Auth < GitPeer::Controller
  include GitPeer::Controller::URITemplates

  uri :logout,          '/logout'
  uri :login,           '/{provider}'
  uri :login_callback,  '/{provider}/callback'

  get :login_callback do
    info = request.env['omniauth.auth'][:info]
    user = {
      :email => info[:email],
      :name => info[:name],
      :avatar => info[:image],
    }
    session[:user] = user
    "<!doctype html>
      <script>
      window.localStorage.setItem('#{key}', JSON.stringify(#{user.to_json}));
      window.close();
      </script>
    "
  end

  get :logout do
    session[:user] = nil
    "<!doctype html>
      <script>
      window.localStorage.removeItem('#{key}');
      window.close();
      </script>
    "
  end

  def key
    config[:key] or 'user'
  end

  def self.provider(klass, *args, &block)
    middleware << proc do
      OmniAuth.configure do |config|
        config.path_prefix = ''
      end
      use OmniAuth::Builder do
        provider klass, *args, &block
      end
    end
  end

end

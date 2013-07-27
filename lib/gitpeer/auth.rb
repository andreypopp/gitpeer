require 'gitpeer/controller'

class GitPeer::Auth < GitPeer::Controller
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
end

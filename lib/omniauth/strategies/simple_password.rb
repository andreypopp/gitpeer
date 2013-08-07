require 'digest/hmac'
require 'omniauth'

class OmniAuth::Strategies::SimplePassword
  include OmniAuth::Strategy

  option :user_model, nil # default set to 'User' below
  option :login_field, :email

  def request_phase
    redirect "/session/new"
  end

  def callback_phase
    if user[:password_digest] != Digest::HMAC.hexdigest(password, @@_secret_key, Digest::SHA1)
      fail!(:invalid_credentials)
    else
      super
    end
  end

  def user
    @user ||= @@_users[login]
  end

  def login
    request[:sessions][options[:login_field].to_s]
  end

  def password
    request[:sessions]['password']
  end

  uid do
    user[:password_digest]
  end

  class << self

    @_users = {}
    @_secret_key = nil

    def secret_key(value)
      @_secret_key = value
    end

    def user(login, password_digest)
      @users[login] = {password_digest: password_digest, login: login}
    end

  end
end

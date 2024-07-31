require 'rodauth'

class RodauthApp < Rodauth::Auth
  configure do
    enable :login, :logout, :create_account, :jwt, :json, :internal_request, :jwt_refresh, :active_sessions
    jwt_secret ENV['JWT_SECRET']
    only_json? true

    expired_jwt_access_token_status { 401 }
    jwt_access_token_period { 3600 }
    hmac_secret ENV['JWT_SECRET']
  end
end

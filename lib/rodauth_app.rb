require 'rodauth'
require_relative './auth_helpers'

class RodauthApp < Rodauth::Auth
  configure do
    enable :login, :logout, :create_account, :jwt, :json, :internal_request, :jwt_refresh, :active_sessions
    jwt_secret ENV['JWT_SECRET']
    only_json? true
    expired_jwt_access_token_status { 401 }
    hmac_secret ENV['JWT_SECRET']

    jwt_decode_opts({ verify_expiration: true })

    jwt_session_hash do
      if account && account_id && account.authenticated?
        acc = Account[account_id]
        super().merge({
                        'roles' => acc.roles.map(&:name),
                        'permissions' => acc.permissions
                      })
      end
    end

    auth_class_eval do
      include AuthHelpers
    end
  end
end

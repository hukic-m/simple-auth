require 'rodauth'

class RodauthApp < Rodauth::Auth
  configure do
    enable :login, :logout, :create_account, :jwt, :json, :internal_request, :jwt_refresh, :active_sessions
    jwt_secret ENV['JWT_SECRET']
    only_json? true
    account_password_hash_column :password_hash
    expired_jwt_access_token_status { 401 }
    jwt_access_token_period { 360 }
    hmac_secret ENV['JWT_SECRET']

    jwt_session_hash do
      whole_account = Account[account_id]
      super().merge(
        {
          'scopes' => whole_account.roles.map(&:name),
          'permissions' => whole_account.scopes
        }
      )
    end
  end
end

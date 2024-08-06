require_relative '../../lib/rodauth_app'

class SimpleAuth
  # plugin :rodauth, json: true, auth_class: RodauthApp
  hash_branch '/v1', 'auth', &:rodauth
end

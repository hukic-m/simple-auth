require_relative '../lib/rodauth_app'

class RodauthRoutes < Roda
  plugin :rodauth, json: true, auth_class: RodauthApp
  # route: POST /auth/login
  # route: POST /auth/create-account
  route(&:rodauth)
end

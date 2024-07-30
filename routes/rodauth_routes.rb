require_relative '../lib/rodauth_app'

class RodauthRoutes < Roda
  plugin :rodauth, json: true, auth_class: RodauthApp
  route(&:rodauth)
end

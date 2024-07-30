require 'roda'
require_relative './lib/db'
require_relative './routes/rodauth_routes'
require_relative './models/account'
require_relative './models/role'
require_relative './models/permission'
require 'dotenv'
Dotenv.load
class App < Roda
  plugin :json

  route do |r|
    r.on 'auth' do
      r.run RodauthRoutes
    end

    r.root do
      { message: 'Welcome to simple-auth' }
    end
  end
end

run App.freeze.app

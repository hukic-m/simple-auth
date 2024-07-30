require 'roda'
require 'dotenv'
Dotenv.load

require_relative './db'
require_relative './models/account'
require_relative './models/role'
require_relative './models/permission'

class App < Roda
  plugin :json

  route do |r|
    r.root do
      { message: 'Welcome to simple-auth' }
    end
  end
end

run App.freeze.app

require 'roda'

require 'dotenv'
Dotenv.load

class App < Roda
  plugin :json

  route do |r|
    r.root do
      { message: 'Welcome to simple-auth' }
    end
  end
end

run App.freeze.app

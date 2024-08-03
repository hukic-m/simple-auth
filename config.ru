# require 'roda'
# require_relative './lib/db'
# require_relative './routes/rodauth_routes'
# require_relative './routes/roles_routes'
# require_relative './routes/permissions_routes'
# require_relative './models/account'
# require_relative './models/role'
# require_relative './models/permission'
# require 'rake'
# require 'dotenv'
# Dotenv.load

# Rake.application.init
# Rake.application.load_rakefile

# # Run migrations before initializing the app
# Rake::Task['db:migrate'].invoke(ENV['RACK_ENV'] || 'development')
# class App < Roda
#   plugin :json
#   plugin :route_list

#   route do |r|
#     # route: GET /auth
#     r.on 'auth' do
#       r.run RodauthRoutes
#     end

#     r.on 'api' do
#       r.on 'v1' do
#         r.on 'roles' do
#           r.run RolesRoutes
#         end

#         r.on 'permissions' do
#           r.run PermissionsRoutes
#         end
#       end
#     end

#     r.root do
#       { message: 'Welcome to simple-auth' }
#     end
#   end
# end

require_relative './app'

run App.freeze.app

require 'dotenv'
require 'roda'
Dotenv.load
require_relative './lib/db'
require_relative './models'
require 'rake'

class SimpleAuth < Roda
  plugin :json
  plugin :route_list
  plugin :default_headers,
         'Content-Type' => 'application/json',
         'X-Content-Type-Options' => 'nosniff'
  plugin :route_csrf
  plugin :hash_branch_view_subdir

  Dir['./routes/**/*.rb'].each do |route_file|
    require_relative route_file.delete_suffix('.rb')
  end

  route do |r|
    r.hash_branches

    r.root do
      { message: 'Welcome to simple-auth' }
    end
  end
end
